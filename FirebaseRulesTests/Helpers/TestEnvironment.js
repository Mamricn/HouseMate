import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";

const currentDirectory = path.dirname(fileURLToPath(import.meta.url));
const rulesPath = path.resolve(currentDirectory, "../../firestore.rules");

export const userIDs = {
  owner: "owner-user",
  member: "member-user",
  stranger: "stranger-user",
};

export async function createTestEnvironment() {
  return initializeTestEnvironment({
    projectId: "demo-housemate",
    firestore: {
      rules: fs.readFileSync(rulesPath, "utf8"),
    },
  });
}

export function firestoreFor(testEnvironment, userID) {
  if (userID == null) {
    return testEnvironment.unauthenticatedContext().firestore();
  }

  return testEnvironment.authenticatedContext(userID).firestore();
}

export async function seedHousehold(testEnvironment) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const database = context.firestore();
    const household = database.doc("households/home-1");

    await household.set({
      household_id: "home-1",
      name: "Test Home",
      invite_code: "TEST123",
      created_by_user_id: userIDs.owner,
      owner_user_id: userIDs.owner,
      member_ids: [userIDs.owner, userIDs.member],
      deletion_state: "",
    });

    await database.doc("household_invites/TEST123").set({
      invite_code: "TEST123",
      household_id: "home-1",
      created_by_user_id: userIDs.owner,
      active: true,
      created_at: new Date(),
    });

    await database.doc(`users/${userIDs.owner}`).set({
      user_id: userIDs.owner,
      name: "Owner",
      household_id: "home-1",
    });

    await database.doc(`users/${userIDs.member}`).set({
      user_id: userIDs.member,
      name: "Member",
      household_id: "home-1",
    });

    await database.doc(`users/${userIDs.stranger}`).set({
      user_id: userIDs.stranger,
      name: "Stranger",
    });

    await database.doc("users/new-owner").set({
      user_id: "new-owner",
      name: "New Owner",
    });

    await database
      .doc(`households/home-1/members/${userIDs.owner}`)
      .set({
        user_id: userIDs.owner,
        household_id: "home-1",
        display_name: "Owner",
      });

    await database
      .doc(`households/home-1/members/${userIDs.member}`)
      .set({
        user_id: userIDs.member,
        household_id: "home-1",
        display_name: "Member",
      });

    await database.doc("households/home-1/tasks/task-1").set({
      task_id: "task-1",
      household_id: "home-1",
      created_by_user_id: userIDs.owner,
      title: "Existing task",
      status: "pending",
    });

    await database
      .doc(`users/${userIDs.member}/notifications/notification-1`)
      .set({
        notification_id: "notification-1",
        recipient_user_id: userIDs.member,
        household_id: "home-1",
        is_read: false,
      });
  });
}
