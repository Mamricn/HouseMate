import { after, before, beforeEach, describe, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from "firebase/firestore";
import {
  createTestEnvironment,
  firestoreFor,
  seedHousehold,
  userIDs,
} from "../Helpers/TestEnvironment.js";

describe("Firestore task rules — household data isolation", () => {
  let testEnvironment;

  before(async () => {
    testEnvironment = await createTestEnvironment();
  });

  beforeEach(async () => {
    await testEnvironment.clearFirestore();
    await seedHousehold(testEnvironment);
  });

  after(async () => {
    await testEnvironment.cleanup();
  });

  test("a household member can read its tasks", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertSucceeds(
      getDoc(doc(database, "households/home-1/tasks/task-1")),
    );
  });

  test("a user outside the household cannot read its tasks", async () => {
    const database = firestoreFor(testEnvironment, userIDs.stranger);

    await assertFails(
      getDoc(doc(database, "households/home-1/tasks/task-1")),
    );
  });

  test("a member can create a correctly identified task", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertSucceeds(
      setDoc(doc(database, "households/home-1/tasks/task-2"), {
        task_id: "task-2",
        household_id: "home-1",
        created_by_user_id: userIDs.member,
        title: "New task",
        status: "pending",
      }),
    );
  });

  test("a member cannot create a task as another user", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertFails(
      setDoc(doc(database, "households/home-1/tasks/task-2"), {
        task_id: "task-2",
        household_id: "home-1",
        created_by_user_id: userIDs.owner,
        title: "Forged task",
        status: "pending",
      }),
    );
  });

  test("a member can update task status but cannot replace its title", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);
    const task = doc(database, "households/home-1/tasks/task-1");

    await assertSucceeds(updateDoc(task, { status: "completed" }));
    await assertFails(updateDoc(task, { title: "Changed title" }));
  });
});
