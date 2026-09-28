import { after, before, beforeEach, describe, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import {
  arrayRemove,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  updateDoc,
  writeBatch,
} from "firebase/firestore";
import {
  createTestEnvironment,
  firestoreFor,
  seedHousehold,
  userIDs,
} from "../Helpers/TestEnvironment.js";

describe("Firestore household rules — membership and ownership", () => {
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

  test("a signed-out user cannot read a household", async () => {
    const database = firestoreFor(testEnvironment, null);

    await assertFails(getDoc(doc(database, "households/home-1")));
  });

  test("a signed-in outsider cannot read a household", async () => {
    const database = firestoreFor(testEnvironment, userIDs.stranger);

    await assertFails(getDoc(doc(database, "households/home-1")));
  });

  test("a signed-in outsider can resolve a minimal invite document", async () => {
    const database = firestoreFor(testEnvironment, userIDs.stranger);

    await assertSucceeds(getDoc(doc(database, "household_invites/TEST123")));
  });

  test("a signed-in user cannot list every household invite", async () => {
    const database = firestoreFor(testEnvironment, userIDs.stranger);

    await assertFails(getDocs(collection(database, "household_invites")));
  });

  test("creating a household atomically creates its protected invite", async () => {
    const database = firestoreFor(testEnvironment, "new-owner");
    const batch = writeBatch(database);

    batch.set(doc(database, "households/home-2"), {
      household_id: "home-2",
      name: "New Home",
      invite_code: "NEW123",
      created_by_user_id: "new-owner",
      owner_user_id: "new-owner",
      member_ids: ["new-owner"],
    });
    batch.set(doc(database, "household_invites/NEW123"), {
      invite_code: "NEW123",
      household_id: "home-2",
      created_by_user_id: "new-owner",
      active: true,
      created_at: new Date(),
    });
    batch.set(doc(database, "households/home-2/members/new-owner"), {
      user_id: "new-owner",
      household_id: "home-2",
      display_name: "New Owner",
    });
    batch.update(doc(database, "users/new-owner"), {
      household_id: "home-2",
    });

    await assertSucceeds(batch.commit());
  });

  test("a valid invite allows the complete atomic join operation", async () => {
    const database = firestoreFor(testEnvironment, userIDs.stranger);
    const batch = writeBatch(database);

    batch.update(doc(database, "households/home-1"), {
      member_ids: arrayUnion(userIDs.stranger),
    });
    batch.set(
      doc(database, `households/home-1/members/${userIDs.stranger}`),
      {
        user_id: userIDs.stranger,
        household_id: "home-1",
        display_name: "Stranger",
      },
    );
    batch.update(doc(database, `users/${userIDs.stranger}`), {
      household_id: "home-1",
    });

    await assertSucceeds(batch.commit());
  });

  test("a regular member cannot change household details", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertFails(
      updateDoc(doc(database, "households/home-1"), {
        name: "Changed by member",
      }),
    );
  });

  test("the owner can remove a member from the household", async () => {
    const database = firestoreFor(testEnvironment, userIDs.owner);

    await assertSucceeds(
      updateDoc(doc(database, "households/home-1"), {
        member_ids: arrayRemove(userIDs.member),
      }),
    );
  });

  test("a regular member cannot delete another member document", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertFails(
      deleteDoc(
        doc(database, `households/home-1/members/${userIDs.owner}`),
      ),
    );
  });

  test("the owner can delete another member document", async () => {
    const database = firestoreFor(testEnvironment, userIDs.owner);

    await assertSucceeds(
      deleteDoc(
        doc(database, `households/home-1/members/${userIDs.member}`),
      ),
    );
  });

  test("a regular member cannot replace or disable an invite", async () => {
    const database = firestoreFor(testEnvironment, userIDs.member);

    await assertFails(
      updateDoc(doc(database, "household_invites/TEST123"), {
        active: false,
      }),
    );
  });

  test("the owner can disable an invite", async () => {
    const database = firestoreFor(testEnvironment, userIDs.owner);

    await assertSucceeds(
      updateDoc(doc(database, "household_invites/TEST123"), {
        active: false,
      }),
    );
  });

  test("a disabled invite prevents a new user from joining", async () => {
    const ownerDatabase = firestoreFor(testEnvironment, userIDs.owner);
    const strangerDatabase = firestoreFor(testEnvironment, userIDs.stranger);

    await assertSucceeds(
      updateDoc(doc(ownerDatabase, "household_invites/TEST123"), {
        active: false,
      }),
    );

    await assertFails(
      updateDoc(doc(strangerDatabase, "households/home-1"), {
        member_ids: arrayUnion(userIDs.stranger),
      }),
    );
  });
});
