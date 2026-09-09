import {initializeApp} from "firebase-admin/app";
import {
  DocumentSnapshot,
  FieldValue,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import {DateTime} from "luxon";

initializeApp();

setGlobalOptions({
  maxInstances: 10,
  region: "europe-west2",
});

type TaskDocument = {
  task_id?: string;
  title?: string;
  assigned_to_user_id?: string;
  created_by_user_id?: string;
  status?: string;
  due_date?: Timestamp;
  reminder_at?: Timestamp;
  participates_in_weekly_rotation?: boolean;
};

type HouseholdDocument = {
  member_ids?: string[];
  owner_user_id?: string;
  created_by_user_id?: string;
  weekly_assignment_last_run_week?: string;
};

type PollDocument = {
  poll_id?: string;
  question?: string;
  created_by_user_id?: string;
};

type BoardPostDocument = {
  post_id?: string;
  text?: string;
  created_by_user_id?: string;
};

type BillDocument = {
  bill_id?: string;
  title?: string;
  created_by_user_id?: string;
  recurrence_series_id?: string;
  status?: string;
};

type HouseReminderDocument = {
  reminder_id?: string;
  title?: string;
  details?: string;
  recurrence?: string;
  reminder_advance?: string;
  next_reminder_at?: Timestamp;
  time_zone_id?: string;
};

type MemberDocument = {
  user_id?: string;
};

/** Creates an in-app notification and sends a push for an assigned chore. */
export const notifyTaskAssigned = onDocumentCreated(
  "households/{householdId}/tasks/{taskId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Task snapshot is missing", {eventId: event.id});
      return;
    }

    const task = snapshot.data() as TaskDocument;
    const recipientUserId = task.assigned_to_user_id;
    const householdId = event.params.householdId;
    const taskId = task.task_id ?? event.params.taskId;

    if (!recipientUserId) {
      logger.info("Task has no assignee; notification skipped", {taskId});
      return;
    }

    if (recipientUserId === task.created_by_user_id) {
      logger.info("Task assigned to its creator; push skipped", {
        taskId,
        recipientUserId,
      });
      return;
    }

    const title = "New chore assigned";
    const message = task.title ?
      `You were assigned: ${task.title}` :
      "A new household chore was assigned to you.";
    const database = getFirestore();
    const notificationRef = database
      .collection("users")
      .doc(recipientUserId)
      .collection("notifications")
      .doc();

    await notificationRef.set({
      notification_id: notificationRef.id,
      recipient_user_id: recipientUserId,
      household_id: householdId,
      created_at: FieldValue.serverTimestamp(),
      type: "taskAssigned",
      title,
      message,
      is_read: false,
      related_entity_id: taskId,
      destination: "household",
    });

    const registrations = await database
      .collection("users")
      .doc(recipientUserId)
      .collection("device_tokens")
      .get();

    if (registrations.empty) {
      logger.info("Recipient has no registered devices", {
        taskId,
        recipientUserId,
      });
      return;
    }

    const results = await Promise.allSettled(
      registrations.docs.map(async (registration) => {
        const fid = registration.get("registration_id") as string | undefined;
        if (!fid) {
          logger.warn("Registration document has no registration_id", {
            path: registration.ref.path,
          });
          return;
        }

        try {
          await getMessaging().send({
            fid,
            notification: {title, body: message},
            data: {
              notificationId: notificationRef.id,
              type: "taskAssigned",
              householdId,
              relatedEntityId: taskId,
              destination: "household",
            },
            apns: {
              payload: {aps: {sound: "default"}},
            },
          });
        } catch (error) {
          const code = getErrorCode(error);
          if (code === "messaging/installation-id-not-registered") {
            await registration.ref.delete();
            logger.info("Removed an inactive device registration", {
              path: registration.ref.path,
            });
            return;
          }

          throw error;
        }
      })
    );

    const failedCount = results.filter(
      (result) => result.status === "rejected"
    ).length;

    if (failedCount > 0) {
      logger.error("Some task notifications could not be sent", {
        taskId,
        recipientUserId,
        failedCount,
      });
      return;
    }

    logger.info("Task assignment notification sent", {
      taskId,
      recipientUserId,
      deviceCount: registrations.size,
    });
  }
);

/** Creates an in-app notification and push for a new household poll. */
export const notifyPollCreated = onDocumentCreated(
  "households/{householdId}/polls/{pollId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Poll snapshot is missing", {eventId: event.id});
      return;
    }

    const poll = snapshot.data() as PollDocument;
    const householdId = event.params.householdId;
    const pollId = poll.poll_id ?? event.params.pollId;
    const creatorUserId = poll.created_by_user_id;

    if (!creatorUserId) {
      logger.warn("Poll has no creator; notification skipped", {pollId});
      return;
    }

    const database = getFirestore();
    const members = await database
      .collection("households")
      .doc(householdId)
      .collection("members")
      .get();
    const recipientUserIds = members.docs
      .map((member) => (member.data() as MemberDocument).user_id)
      .filter((userId): userId is string =>
        Boolean(userId) && userId !== creatorUserId
      );

    if (recipientUserIds.length === 0) {
      logger.info("Poll has no other household members to notify", {pollId});
      return;
    }

    const title = "New household poll";
    const message = poll.question ?
      `Vote now: ${poll.question}` :
      "A new poll is waiting for your vote.";
    const results = await Promise.allSettled(
      recipientUserIds.map((recipientUserId) =>
        createNotificationAndSendPush({
          recipientUserId,
          householdId,
          relatedEntityId: pollId,
          type: "newPoll",
          destination: "housemates",
          title,
          message,
        })
      )
    );
    const failedCount = results.filter(
      (result) => result.status === "rejected"
    ).length;

    if (failedCount > 0) {
      logger.error("Some poll notifications could not be processed", {
        pollId,
        recipientCount: recipientUserIds.length,
        failedCount,
      });
      return;
    }

    logger.info("New poll notifications processed", {
      pollId,
      recipientCount: recipientUserIds.length,
    });
  }
);

/** Creates an in-app notification and push for a new board post. */
export const notifyBoardPostCreated = onDocumentCreated(
  "households/{householdId}/board_posts/{postId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Board post snapshot is missing", {eventId: event.id});
      return;
    }

    const post = snapshot.data() as BoardPostDocument;
    const householdId = event.params.householdId;
    const postId = post.post_id ?? event.params.postId;
    const creatorUserId = post.created_by_user_id;

    if (!creatorUserId) {
      logger.warn("Board post has no creator; notification skipped", {postId});
      return;
    }

    const database = getFirestore();
    const members = await database
      .collection("households")
      .doc(householdId)
      .collection("members")
      .get();
    const recipientUserIds = members.docs
      .map((member) => (member.data() as MemberDocument).user_id)
      .filter((userId): userId is string =>
        Boolean(userId) && userId !== creatorUserId
      );

    if (recipientUserIds.length === 0) {
      logger.info("Board post has no other members to notify", {postId});
      return;
    }

    const title = "New household post";
    const message = makePreview(
      post.text,
      "A new post was added to your household board."
    );
    const results = await Promise.allSettled(
      recipientUserIds.map((recipientUserId) =>
        createNotificationAndSendPush({
          recipientUserId,
          householdId,
          relatedEntityId: postId,
          type: "newBoardPost",
          destination: "housemates",
          title,
          message,
        })
      )
    );
    const failedCount = results.filter(
      (result) => result.status === "rejected"
    ).length;

    if (failedCount > 0) {
      logger.error("Some board post notifications could not be processed", {
        postId,
        recipientCount: recipientUserIds.length,
        failedCount,
      });
      return;
    }

    logger.info("New board post notifications processed", {
      postId,
      recipientCount: recipientUserIds.length,
    });
  }
);

/** Creates an in-app notification and push for a new household bill. */
export const notifyBillCreated = onDocumentCreated(
  "households/{householdId}/bills/{billId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Bill snapshot is missing", {eventId: event.id});
      return;
    }

    const bill = snapshot.data() as BillDocument;
    const householdId = event.params.householdId;
    const billId = bill.bill_id ?? event.params.billId;
    const creatorUserId = bill.created_by_user_id;

    if (!creatorUserId) {
      logger.warn("Bill has no creator; notification skipped", {billId});
      return;
    }

    if (bill.recurrence_series_id &&
        bill.recurrence_series_id !== billId) {
      logger.info("Automatically generated recurring bill skipped", {billId});
      return;
    }

    const database = getFirestore();
    const members = await database
      .collection("households")
      .doc(householdId)
      .collection("members")
      .get();
    const recipientUserIds = members.docs
      .map((member) => (member.data() as MemberDocument).user_id)
      .filter((userId): userId is string =>
        Boolean(userId) && userId !== creatorUserId
      );

    if (recipientUserIds.length === 0) {
      logger.info("Bill has no other household members to notify", {billId});
      return;
    }

    const title = "New household bill";
    const message = bill.title ?
      `${bill.title} was added to your household.` :
      "A new bill was added to your household.";
    const results = await Promise.allSettled(
      recipientUserIds.map((recipientUserId) =>
        createNotificationAndSendPush({
          recipientUserId,
          householdId,
          relatedEntityId: billId,
          type: "newBill",
          destination: "household",
          title,
          message,
        })
      )
    );
    const failedCount = results.filter(
      (result) => result.status === "rejected"
    ).length;

    if (failedCount > 0) {
      logger.error("Some bill notifications could not be processed", {
        billId,
        recipientCount: recipientUserIds.length,
        failedCount,
      });
      return;
    }

    logger.info("New bill notifications processed", {
      billId,
      recipientCount: recipientUserIds.length,
    });
  }
);

/** Rotates opted-in chores fairly between household members every Monday. */
export const rotateWeeklyChores = onSchedule(
  {
    schedule: "5 0 * * 1",
    timeZone: "Europe/London",
    maxInstances: 1,
  },
  async () => {
    const now = DateTime.now().setZone("Europe/London");
    const weekStart = now.startOf("week");
    const weekKey = weekStart.toFormat("kkkk-'W'WW");
    const epochWeek = Math.floor(weekStart.toMillis() / 604800000);
    const database = getFirestore();
    const households = await database.collection("households")
      .where("automatic_weekly_assignment_enabled", "==", true)
      .get();

    for (const householdSnapshot of households.docs) {
      await rotateHouseholdChores({
        householdSnapshot,
        weekStart,
        weekKey,
        epochWeek,
        recordScheduledRun: true,
      });
    }
  }
);

/** Runs weekly assignment immediately after an owner sends a Dev command. */
export const runWeeklyAssignmentCommand = onDocumentCreated(
  "households/{householdId}/developer_commands/{commandId}",
  async (event) => {
    const commandSnapshot = event.data;
    if (!commandSnapshot) {
      return;
    }

    const command = commandSnapshot.data();
    const householdId = event.params.householdId;
    const householdSnapshot = await getFirestore()
      .collection("households")
      .doc(householdId)
      .get();
    const household = householdSnapshot.data() as
      HouseholdDocument | undefined;
    const ownerUserId = household?.owner_user_id ??
      household?.created_by_user_id;

    try {
      if (command.command !== "run_weekly_assignment" ||
          command.requested_by_user_id !== ownerUserId) {
        logger.warn("Rejected weekly assignment command", {
          householdId,
          commandId: commandSnapshot.id,
        });
        return;
      }

      const now = DateTime.now().setZone("Europe/London");
      const weekStart = now.startOf("week");
      await rotateHouseholdChores({
        householdSnapshot,
        weekStart,
        weekKey: `manual-${commandSnapshot.id}`,
        epochWeek: Math.floor(weekStart.toMillis() / 604800000),
        recordScheduledRun: false,
      });
    } finally {
      await commandSnapshot.ref.delete();
    }
  }
);

type RotationInput = {
  householdSnapshot: DocumentSnapshot;
  weekStart: DateTime;
  weekKey: string;
  epochWeek: number;
  recordScheduledRun: boolean;
};

/**
 * Performs one household rotation for a schedule or an owner Dev command.
 * @param {RotationInput} input Household, week and execution mode.
 * @return {Promise<void>} Completion of task updates and notifications.
 */
async function rotateHouseholdChores(input: RotationInput): Promise<void> {
  const household = input.householdSnapshot.data() as
    HouseholdDocument | undefined;
  if (!household) {
    return;
  }

  if (input.recordScheduledRun &&
      household.weekly_assignment_last_run_week === input.weekKey) {
    return;
  }

  const memberIds = [...new Set(household.member_ids ?? [])].sort();
  if (memberIds.length === 0) {
    logger.warn("Weekly assignment skipped: household has no members", {
      householdId: input.householdSnapshot.id,
    });
    return;
  }

  const tasks = await input.householdSnapshot.ref.collection("tasks")
    .where("participates_in_weekly_rotation", "==", true)
    .limit(450)
    .get();
  const sortedTasks = tasks.docs.sort((left, right) =>
    left.id.localeCompare(right.id)
  );
  const database = getFirestore();
  const batch = database.batch();
  const assignments: Array<{
    taskId: string;
    title?: string;
    recipientUserId: string;
  }> = [];

  sortedTasks.forEach((taskSnapshot, index) => {
    const task = taskSnapshot.data() as TaskDocument;
    const currentMemberIndex = memberIds.indexOf(
      task.assigned_to_user_id ?? ""
    );
    const recipientIndex = input.recordScheduledRun ?
      (input.epochWeek + index) % memberIds.length :
      (Math.max(currentMemberIndex, -1) + 1) % memberIds.length;
    const recipientUserId = memberIds[recipientIndex];
    const update: Record<string, unknown> = {
      assigned_to_user_id: recipientUserId,
      status: "pending",
      last_weekly_rotation_at: FieldValue.serverTimestamp(),
    };

    if (task.due_date) {
      const oldDueDate = DateTime.fromMillis(
        task.due_date.toMillis(),
        {zone: "Europe/London"}
      );
      const newDueDate = input.weekStart
        .plus({days: oldDueDate.weekday - 1})
        .set({
          hour: oldDueDate.hour,
          minute: oldDueDate.minute,
          second: oldDueDate.second,
          millisecond: oldDueDate.millisecond,
        });
      const shiftMilliseconds = newDueDate.toMillis() -
        oldDueDate.toMillis();

      update.due_date = Timestamp.fromMillis(newDueDate.toMillis());
      if (task.reminder_at) {
        update.reminder_at = Timestamp.fromMillis(
          task.reminder_at.toMillis() + shiftMilliseconds
        );
      }
    }

    batch.update(taskSnapshot.ref, update);
    assignments.push({
      taskId: task.task_id ?? taskSnapshot.id,
      title: task.title,
      recipientUserId,
    });
  });

  if (input.recordScheduledRun) {
    batch.update(input.householdSnapshot.ref, {
      weekly_assignment_last_run_week: input.weekKey,
      weekly_assignment_last_run_at: FieldValue.serverTimestamp(),
    });
  } else {
    batch.update(input.householdSnapshot.ref, {
      weekly_assignment_last_manual_run_at: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();

  const notificationResults = await Promise.allSettled(
    assignments.map((assignment) => createNotificationAndSendPush({
      notificationId: `weeklyAssignment-${input.weekKey}-${assignment.taskId}`,
      recipientUserId: assignment.recipientUserId,
      householdId: input.householdSnapshot.id,
      relatedEntityId: assignment.taskId,
      type: "weeklyTaskAssigned",
      destination: "household",
      preferenceField: "task_notifications_enabled",
      title: "Your chore for this week",
      message: assignment.title ?? "A household chore was assigned to you.",
    }))
  );
  const failedCount = notificationResults.filter(
    (result) => result.status === "rejected"
  ).length;

  logger.info("Weekly chores rotated", {
    householdId: input.householdSnapshot.id,
    taskCount: assignments.length,
    failedNotificationCount: failedCount,
    weekKey: input.weekKey,
  });
}

/** Sends task and bill reminders whose selected delivery time has arrived. */
export const sendDueReminders = onSchedule(
  {
    schedule: "every 15 minutes",
    timeZone: "Europe/London",
    maxInstances: 1,
  },
  async () => {
    const now = Timestamp.now();
    const lookback = Timestamp.fromMillis(
      now.toMillis() - 24 * 60 * 60 * 1000
    );
    const database = getFirestore();
    const [tasks, bills, houseReminders] = await Promise.all([
      database.collectionGroup("tasks")
        .where("reminder_at", ">", lookback)
        .where("reminder_at", "<=", now)
        .get(),
      database.collectionGroup("bills")
        .where("reminder_at", ">", lookback)
        .where("reminder_at", "<=", now)
        .get(),
      database.collectionGroup("house_reminders")
        .where("next_reminder_at", ">", lookback)
        .where("next_reminder_at", "<=", now)
        .get(),
    ]);

    const taskResults = await Promise.allSettled(
      tasks.docs.map(async (document) => {
        const task = document.data() as TaskDocument;
        const recipientUserId = task.assigned_to_user_id;
        if (!recipientUserId || task.status !== "pending") {
          return;
        }

        const householdId = document.ref.parent.parent?.id;
        if (!householdId) {
          logger.warn("Could not resolve task household", {
            path: document.ref.path,
          });
          return;
        }

        const taskId = task.task_id ?? document.id;
        await createNotificationAndSendPush({
          notificationId: `taskDue-${taskId}`,
          recipientUserId,
          householdId,
          relatedEntityId: taskId,
          type: "taskDue",
          destination: "household",
          preferenceField: "task_notifications_enabled",
          title: task.title ?? "Chore reminder",
          message: "Your chore is due soon.",
        });
      })
    );

    const billResults = await Promise.allSettled(
      bills.docs.map(async (document) => {
        const bill = document.data() as BillDocument;
        if (bill.status === "paid") {
          return;
        }

        const householdId = document.ref.parent.parent?.id;
        if (!householdId) {
          logger.warn("Could not resolve bill household", {
            path: document.ref.path,
          });
          return;
        }

        const billId = bill.bill_id ?? document.id;
        const members = await database
          .collection("households")
          .doc(householdId)
          .collection("members")
          .get();
        const recipientUserIds = members.docs
          .map((member) => (member.data() as MemberDocument).user_id)
          .filter((userId): userId is string => Boolean(userId));

        await Promise.all(recipientUserIds.map((recipientUserId) =>
          createNotificationAndSendPush({
            notificationId: `billDue-${billId}-${recipientUserId}`,
            recipientUserId,
            householdId,
            relatedEntityId: billId,
            type: "billDue",
            destination: "household",
            preferenceField: "bill_notifications_enabled",
            title: bill.title ?? "Bill reminder",
            message: "A household bill is due soon.",
          })
        ));
      })
    );

    const houseReminderResults = await Promise.allSettled(
      houseReminders.docs.map(async (document) => {
        const reminder = document.data() as HouseReminderDocument;
        const scheduledAt = reminder.next_reminder_at;
        if (!scheduledAt) {
          return;
        }

        const householdId = document.ref.parent.parent?.id;
        if (!householdId) {
          logger.warn("Could not resolve house reminder household", {
            path: document.ref.path,
          });
          return;
        }

        const reminderId = reminder.reminder_id ?? document.id;
        const members = await database
          .collection("households")
          .doc(householdId)
          .collection("members")
          .get();
        const recipientUserIds = members.docs
          .map((member) => (member.data() as MemberDocument).user_id)
          .filter((userId): userId is string => Boolean(userId));
        const occurrenceKey = scheduledAt.toMillis();

        await Promise.all(recipientUserIds.map((recipientUserId) =>
          createNotificationAndSendPush({
            notificationId:
              `houseReminder-${reminderId}-${occurrenceKey}-${recipientUserId}`,
            recipientUserId,
            householdId,
            relatedEntityId: reminderId,
            type: "houseReminder",
            destination: "housemates",
            preferenceField: "house_reminder_notifications_enabled",
            title: reminder.title ?? "Household reminder",
            message: reminder.details ??
              houseReminderMessage(reminder.reminder_advance),
          })
        ));

        const nextReminderAt = nextRecurringDate(
          scheduledAt,
          reminder.recurrence,
          reminder.time_zone_id
        );
        const update: Record<string, unknown> = {
          reminder_last_sent_at: FieldValue.serverTimestamp(),
        };
        update.next_reminder_at = nextReminderAt ?? FieldValue.delete();
        await document.ref.update(update);
      })
    );

    const failedCount = [
      ...taskResults,
      ...billResults,
      ...houseReminderResults,
    ].filter(
      (result) => result.status === "rejected"
    ).length;

    logger.info("Due reminder scan completed", {
      taskCount: tasks.size,
      billCount: bills.size,
      houseReminderCount: houseReminders.size,
      failedCount,
    });

    if (failedCount > 0) {
      throw new Error(`${failedCount} reminder operation(s) failed.`);
    }
  }
);

/**
 * Returns the next delivery timestamp while preserving local wall-clock time.
 * @param {Timestamp} current Current reminder delivery time.
 * @param {string | undefined} recurrence Stored recurrence option.
 * @param {string | undefined} timeZone IANA time-zone identifier.
 * @return {Timestamp | undefined} Next delivery time for recurring reminders.
 */
function nextRecurringDate(
  current: Timestamp,
  recurrence: string | undefined,
  timeZone: string | undefined
): Timestamp | undefined {
  const date = DateTime.fromJSDate(current.toDate(), {
    zone: timeZone ?? "Europe/London",
  });
  let next: DateTime;

  switch (recurrence) {
  case "weekly":
    next = date.plus({weeks: 1});
    break;
  case "biweekly":
    next = date.plus({weeks: 2});
    break;
  case "monthly":
    next = date.plus({months: 1});
    break;
  case "quarterly":
    next = date.plus({months: 3});
    break;
  case "yearly":
    next = date.plus({years: 1});
    break;
  default:
    return undefined;
  }

  return Timestamp.fromDate(next.toJSDate());
}

/**
 * Creates the default body for a house reminder without custom details.
 * @param {string | undefined} advance Selected reminder advance.
 * @return {string} User-facing reminder message.
 */
function houseReminderMessage(advance: string | undefined): string {
  switch (advance) {
  case "sameDay":
    return "Scheduled for today.";
  case "oneDayBefore":
    return "Scheduled for tomorrow.";
  case "twoDaysBefore":
    return "Scheduled in 2 days.";
  case "oneWeekBefore":
    return "Scheduled in 1 week.";
  default:
    return "A household event is coming up.";
  }
}

type NotificationInput = {
  notificationId?: string;
  recipientUserId: string;
  householdId: string;
  relatedEntityId: string;
  type: string;
  destination: string;
  title: string;
  message: string;
  preferenceField?: string;
};

/**
 * Stores one in-app notification and sends it to every registered device.
 * @param {NotificationInput} input Notification content and recipient.
 * @return {Promise<void>} Completion of storage and push attempts.
 */
async function createNotificationAndSendPush(
  input: NotificationInput
): Promise<void> {
  const database = getFirestore();
  const userReference = database.collection("users").doc(input.recipientUserId);
  const notificationRef = input.notificationId ?
    userReference.collection("notifications").doc(input.notificationId) :
    userReference.collection("notifications").doc();

  try {
    await notificationRef.create({
      notification_id: notificationRef.id,
      recipient_user_id: input.recipientUserId,
      household_id: input.householdId,
      created_at: FieldValue.serverTimestamp(),
      type: input.type,
      title: input.title,
      message: input.message,
      is_read: false,
      related_entity_id: input.relatedEntityId,
      destination: input.destination,
    });
  } catch (error) {
    if (input.notificationId && isAlreadyExistsError(error)) {
      logger.info("Notification was already processed", {
        notificationId: input.notificationId,
      });
      return;
    }

    throw error;
  }

  const registrations = await userReference.collection("device_tokens").get();
  if (registrations.empty) {
    logger.info("Recipient has no registered devices", {
      recipientUserId: input.recipientUserId,
      type: input.type,
    });
    return;
  }

  const results = await Promise.allSettled(
    registrations.docs.map(async (registration) => {
      if (input.preferenceField &&
          registration.get(input.preferenceField) === false) {
        return;
      }

      const fid = registration.get("registration_id") as string | undefined;
      if (!fid) {
        logger.warn("Registration document has no registration_id", {
          path: registration.ref.path,
        });
        return;
      }

      try {
        await getMessaging().send({
          fid,
          notification: {title: input.title, body: input.message},
          data: {
            notificationId: notificationRef.id,
            type: input.type,
            householdId: input.householdId,
            relatedEntityId: input.relatedEntityId,
            destination: input.destination,
          },
          apns: {payload: {aps: {sound: "default"}}},
        });
      } catch (error) {
        if (getErrorCode(error) ===
            "messaging/installation-id-not-registered") {
          await registration.ref.delete();
          logger.info("Removed an inactive device registration", {
            path: registration.ref.path,
          });
          return;
        }

        throw error;
      }
    })
  );
  const rejectedResults = results.filter(
    (result) => result.status === "rejected"
  );

  if (rejectedResults.length > 0) {
    throw new Error(
      `Push failed for ${rejectedResults.length} registered device(s).`
    );
  }
}

/**
 * Makes a compact push body while keeping the full content in Firestore.
 * @param {string | undefined} value Original user-authored text.
 * @param {string} fallback Text used when the original value is empty.
 * @return {string} A single-line preview no longer than 140 characters.
 */
function makePreview(value: string | undefined, fallback: string): string {
  const normalized = value?.replace(/\s+/g, " ").trim();
  if (!normalized) {
    return fallback;
  }

  if (normalized.length <= 140) {
    return normalized;
  }

  return `${normalized.slice(0, 137)}...`;
}

/**
 * Returns Firebase's machine-readable error code when one is available.
 * @param {unknown} error Error thrown by Firebase Admin.
 * @return {string | undefined} Firebase error code, when present.
 */
function getErrorCode(error: unknown): string | undefined {
  if (typeof error !== "object" || error === null || !("code" in error)) {
    return undefined;
  }

  return String(error.code);
}

/**
 * Checks whether Firestore rejected create because the document exists.
 * @param {unknown} error Error thrown by Firestore.
 * @return {boolean} Whether the error represents ALREADY_EXISTS.
 */
function isAlreadyExistsError(error: unknown): boolean {
  const code = getErrorCode(error);
  return code === "6" || code === "already-exists" ||
    code === "firestore/already-exists";
}
