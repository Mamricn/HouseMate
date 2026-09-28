import { after, before, beforeEach, describe, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import {
  deleteDoc,
  doc,
  getDoc,
  updateDoc,
} from "firebase/firestore";
import {
  createTestEnvironment,
  firestoreFor,
  seedHousehold,
  userIDs,
} from "../Helpers/TestEnvironment.js";

describe("Firestore user rules — private profiles and notifications", () => {
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

  test("a user can read their own profile", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertSucceeds(getDoc(doc(database, `users/${userIDs.member}`)));
  });

  test("a user cannot read another user's profile", async () => {
    const database = firestoreFor(testEnvironment, userIDs.stranger);

    await assertFails(getDoc(doc(database, `users/${userIDs.member}`)));
  });

  test("a notification recipient can mark it as read", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertSucceeds(
      updateDoc(
        doc(
          database,
          `users/${userIDs.member}/notifications/notification-1`,
        ),
        { is_read: true },
      ),
    );
  });

  test("a notification recipient cannot change protected fields", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertFails(
      updateDoc(
        doc(
          database,
          `users/${userIDs.member}/notifications/notification-1`,
        ),
        { recipient_user_id: userIDs.stranger },
      ),
    );
  });

  test("another user cannot delete somebody else's notification", async () => {
    const database = firestoreFor(testEnvironment, userIDs.stranger);

    await assertFails(
      deleteDoc(
        doc(
          database,
          `users/${userIDs.member}/notifications/notification-1`,
        ),
      ),
    );
  });
});
