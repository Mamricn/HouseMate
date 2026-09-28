//
//  FirebaseHouseholdService.swift
//  HouseMate
//
//  Created by Marcin Turek on 26/08/2026.
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseHouseholdService: HouseholdServiceProtocol {

    private let database: Firestore

    private var householdsCollection: CollectionReference {
        database.collection("households")
    }

    private var householdInvitesCollection: CollectionReference {
        database.collection("household_invites")
    }

    var updatesUserHouseholdAtomically: Bool {
        true
    }

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func createHousehold(name: String, owner: UserModel) async throws -> HouseholdModel {
        guard owner.householdId == nil else {
            throw HouseholdServiceError.userAlreadyHasHousehold
        }

        let normalizedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedName.isEmpty else {
            throw HouseholdServiceError.invalidName
        }

        let inviteCode = try await makeUniqueInviteCode()
        let householdReference = householdsCollection.document()

        let household = HouseholdModel(
            householdId: householdReference.documentID,
            createdAt: .now,
            name: normalizedName,
            inviteCode: inviteCode,
            createdByUserId: owner.userId,
            memberIds: [owner.userId]
        )

        let member = makeMember(
            user: owner,
            householdID: household.householdId
        )

        let householdData = try Firestore.Encoder().encode(
            household
        )

        let memberData = try Firestore.Encoder().encode(
            member
        )

        let memberReference = householdReference
            .collection("members")
            .document(owner.userId)

        let inviteReference = householdInvitesCollection
            .document(inviteCode)

        let userReference = database
            .collection("users")
            .document(owner.userId)

        let batch = database.batch()

        batch.setData(
            householdData,
            forDocument: householdReference
        )

        batch.setData(
            memberData,
            forDocument: memberReference
        )

        batch.setData(
            [
                "invite_code": inviteCode,
                "household_id": household.householdId,
                "created_by_user_id": owner.userId,
                "active": true,
                "created_at": FieldValue.serverTimestamp()
            ],
            forDocument: inviteReference
        )

        batch.updateData(
            ["household_id": householdReference.documentID],
            forDocument: userReference
        )

        try await batch.commit()

        return household
    }

    func joinHousehold(inviteCode: String, user: UserModel) async throws -> HouseholdModel {
        guard user.householdId == nil else {
            throw HouseholdServiceError.userAlreadyHasHousehold
        }

        let normalizedCode = normalize(inviteCode)

        guard normalizedCode.count == 6 else {
            throw HouseholdServiceError.invalidInviteCode
        }

        let householdReference = try await householdReference(
            forInviteCode: normalizedCode
        )

        guard let householdReference else {
            throw HouseholdServiceError.householdNotFound
        }

        let member = makeMember(
            user: user,
            householdID: householdReference.documentID
        )

        let memberData = try Firestore.Encoder().encode(
            member
        )

        let memberReference = householdReference
            .collection("members")
            .document(user.userId)

        let userReference = database
            .collection("users")
            .document(user.userId)

        let batch = database.batch()

        batch.updateData(
            [
                "member_ids": FieldValue.arrayUnion([
                    user.userId
                ])
            ],
            forDocument: householdReference
        )

        batch.setData(
            memberData,
            forDocument: memberReference,
            merge: true
        )

        batch.updateData(
            ["household_id": householdReference.documentID],
            forDocument: userReference
        )

        try await batch.commit()

        let householdSnapshot = try await householdReference.getDocument()

        guard householdSnapshot.exists,
              let householdData = householdSnapshot.data()
        else {
            throw HouseholdServiceError.householdNotFound
        }

        return try Firestore.Decoder().decode(
            HouseholdModel.self,
            from: householdData
        )
    }

    func fetchHousehold(householdID: String) async throws -> HouseholdModel? {
        let snapshot = try await householdsCollection
            .document(householdID)
            .getDocument()

        guard snapshot.exists,
              let data = snapshot.data()
        else {
            return nil
        }

        let household = try Firestore.Decoder().decode(
            HouseholdModel.self,
            from: data
        )

        do {
            try await ensureInviteLookup(
                for: household,
                requestedByUserID: household.ownerUserId
            )
        } catch {
            // Invite migration must never prevent an existing member from
            // opening their household. The owner can retry on the next load.
            #if DEBUG
            print("Invite lookup backfill failed: \(error.localizedDescription)")
            #endif
        }

        return household
    }

    func fetchMembers(householdID: String) async throws -> [HouseholdMemberModel] {
        let snapshot = try await householdsCollection
            .document(householdID)
            .collection("members")
            .getDocuments()

        return try snapshot.documents
            .map { document in
                try Firestore.Decoder().decode(
                    HouseholdMemberModel.self,
                    from: document.data()
                )
            }
            .sorted {
                ($0.joinedAt ?? .distantPast) < ($1.joinedAt ?? .distantPast)
            }
    }

    func updateAutomaticWeeklyAssignment(
        householdID: String,
        isEnabled: Bool
    ) async throws {
        try await householdsCollection
            .document(householdID)
            .updateData([
                "automatic_weekly_assignment_enabled": isEnabled
            ])
    }

    func runWeeklyAssignmentNow(
        householdID: String,
        requestedByUserID: String
    ) async throws {
        let commandReference = householdsCollection
            .document(householdID)
            .collection("developer_commands")
            .document()

        try await commandReference.setData([
            "command": "run_weekly_assignment",
            "requested_by_user_id": requestedByUserID,
            "created_at": FieldValue.serverTimestamp()
        ])
    }

    func removeMember(
        householdID: String,
        memberUserID: String,
        requestedByUserID: String
    ) async throws {
        let householdReference = householdsCollection.document(
            householdID
        )
        let snapshot = try await householdReference.getDocument()

        guard snapshot.exists,
              let data = snapshot.data()
        else {
            throw HouseholdServiceError.householdNotFound
        }

        let household = try Firestore.Decoder().decode(
            HouseholdModel.self,
            from: data
        )

        guard household.isOwner(userID: requestedByUserID) else {
            throw HouseholdServiceError.ownerPermissionRequired
        }

        guard memberUserID != household.ownerUserId else {
            throw HouseholdServiceError.ownerCannotBeRemoved
        }

        guard household.memberIds.contains(memberUserID) else {
            throw HouseholdServiceError.memberNotFound
        }

        let memberReference = householdReference
            .collection("members")
            .document(memberUserID)
        let userReference = database
            .collection("users")
            .document(memberUserID)
        let batch = database.batch()

        batch.updateData(
            [
                "member_ids": FieldValue.arrayRemove([
                    memberUserID
                ])
            ],
            forDocument: householdReference
        )
        batch.deleteDocument(memberReference)
        batch.updateData(
            ["household_id": FieldValue.delete()],
            forDocument: userReference
        )

        try await batch.commit()
    }

    func transferOwnership(
        householdID: String,
        newOwnerUserID: String,
        requestedByUserID: String
    ) async throws {
        let householdReference = householdsCollection.document(
            householdID
        )
        let snapshot = try await householdReference.getDocument()

        guard snapshot.exists,
              let data = snapshot.data()
        else {
            throw HouseholdServiceError.householdNotFound
        }

        let household = try Firestore.Decoder().decode(
            HouseholdModel.self,
            from: data
        )

        guard household.isOwner(userID: requestedByUserID) else {
            throw HouseholdServiceError.ownerPermissionRequired
        }

        guard newOwnerUserID != requestedByUserID,
              household.memberIds.contains(newOwnerUserID)
        else {
            throw HouseholdServiceError.memberNotFound
        }

        try await householdReference.updateData([
            "owner_user_id": newOwnerUserID
        ])
    }

    func leaveHousehold(
        householdID: String,
        userID: String
    ) async throws {
        let householdReference = householdsCollection.document(
            householdID
        )
        let snapshot = try await householdReference.getDocument()

        guard snapshot.exists,
              let data = snapshot.data()
        else {
            throw HouseholdServiceError.householdNotFound
        }

        let household = try Firestore.Decoder().decode(
            HouseholdModel.self,
            from: data
        )

        guard !household.isOwner(userID: userID) else {
            throw HouseholdServiceError.ownershipTransferRequired
        }

        guard household.memberIds.contains(userID) else {
            throw HouseholdServiceError.memberNotFound
        }

        let batch = database.batch()

        batch.updateData(
            ["member_ids": FieldValue.arrayRemove([userID])],
            forDocument: householdReference
        )
        batch.deleteDocument(
            householdReference
                .collection("members")
                .document(userID)
        )
        batch.updateData(
            ["household_id": FieldValue.delete()],
            forDocument: database
                .collection("users")
                .document(userID)
        )

        try await batch.commit()
    }

    func deleteHousehold(
        householdID: String,
        requestedByUserID: String
    ) async throws {
        let householdReference = householdsCollection.document(
            householdID
        )
        let snapshot = try await householdReference.getDocument()

        guard snapshot.exists,
              let data = snapshot.data()
        else {
            throw HouseholdServiceError.householdNotFound
        }

        let household = try Firestore.Decoder().decode(
            HouseholdModel.self,
            from: data
        )

        guard household.isOwner(userID: requestedByUserID) else {
            throw HouseholdServiceError.ownerPermissionRequired
        }

        try await householdReference.setData(
            ["deletion_state": "deleting"],
            merge: true
        )

        let subcollectionNames = [
            "tasks",
            "shopping_items",
            "shopping_lists",
            "bills",
            "house_reminders",
            "polls",
            "board_posts"
        ]
        var referencesToDelete: [DocumentReference] = []

        for collectionName in subcollectionNames {
            let collectionSnapshot = try await householdReference
                .collection(collectionName)
                .getDocuments()

            referencesToDelete.append(
                contentsOf: collectionSnapshot.documents.map(\.reference)
            )
        }

        for memberUserID in household.memberIds {
            let notificationsSnapshot = try await database
                .collection("users")
                .document(memberUserID)
                .collection("notifications")
                .whereField("household_id", isEqualTo: householdID)
                .getDocuments()

            referencesToDelete.append(
                contentsOf: notificationsSnapshot.documents.map(\.reference)
            )
        }

        try await deleteDocumentsInBatches(referencesToDelete)

        try await clearMembershipsInBatches(
            household.memberIds,
            householdReference: householdReference
        )

        let inviteReference = householdInvitesCollection.document(
            household.inviteCode
        )
        let inviteSnapshot = try await inviteReference.getDocument()
        let finalBatch = database.batch()

        if inviteSnapshot.exists {
            finalBatch.deleteDocument(inviteReference)
        }

        finalBatch.deleteDocument(householdReference)
        try await finalBatch.commit()
    }

    func observeMembers(
        householdID: String,
        onChange: @escaping (Result<[HouseholdMemberModel], Error>) -> Void
    ) -> ServiceObservation? {
        let listener = householdsCollection
            .document(householdID)
            .collection("members")
            .order(by: "joined_at")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                do {
                    let members = try snapshot?.documents.map {
                        try Firestore.Decoder().decode(
                            HouseholdMemberModel.self,
                            from: $0.data()
                        )
                    } ?? []

                    onChange(.success(members))
                } catch {
                    onChange(.failure(error))
                }
            }

        return ServiceObservation(cancellation: listener.remove)
    }

    private func makeUniqueInviteCode() async throws -> String {
        for _ in 0..<10 {
            let inviteCode = Self.makeInviteCode()

            let snapshot = try await householdInvitesCollection
                .document(inviteCode)
                .getDocument()

            if !snapshot.exists {
                return inviteCode
            }
        }

        throw HouseholdServiceError.unableToCreateInviteCode
    }

    private func householdReference(
        forInviteCode inviteCode: String
    ) async throws -> DocumentReference? {
        let inviteSnapshot = try await householdInvitesCollection
            .document(inviteCode)
            .getDocument()

        if inviteSnapshot.exists {
            guard let householdID =
                    inviteSnapshot.data()?["household_id"] as? String,
                  !householdID.isEmpty,
                  inviteSnapshot.data()?["active"] as? Bool != false
            else {
                return nil
            }

            return householdsCollection.document(householdID)
        }

        // Temporary compatibility path for households created before the
        // dedicated invite lookup collection was introduced. Remove this
        // query after all existing invite documents have been backfilled.
        let legacySnapshot = try await householdsCollection
            .whereField("invite_code", isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments()

        return legacySnapshot.documents.first?.reference
    }

    func ensureInviteLookup(
        for household: HouseholdModel,
        requestedByUserID: String
    ) async throws {
        guard requestedByUserID == household.ownerUserId else {
            throw HouseholdServiceError.ownerPermissionRequired
        }

        let inviteReference = householdInvitesCollection.document(
            household.inviteCode
        )
        let inviteSnapshot = try await inviteReference.getDocument(
            source: .server
        )

        guard !inviteSnapshot.exists else { return }

        try await inviteReference.setData([
            "invite_code": household.inviteCode,
            "household_id": household.householdId,
            "created_by_user_id": household.ownerUserId,
            "active": true,
            "created_at": FieldValue.serverTimestamp()
        ])

        let savedInvite = try await inviteReference.getDocument(
            source: .server
        )

        guard savedInvite.exists else {
            throw HouseholdServiceError.unableToCreateInviteCode
        }
    }

    private func deleteDocumentsInBatches(
        _ references: [DocumentReference]
    ) async throws {
        let batchSize = 450

        for startIndex in stride(
            from: 0,
            to: references.count,
            by: batchSize
        ) {
            let endIndex = min(
                startIndex + batchSize,
                references.count
            )
            let batch = database.batch()

            for reference in references[startIndex..<endIndex] {
                batch.deleteDocument(reference)
            }

            try await batch.commit()
        }
    }

    private func clearMembershipsInBatches(
        _ memberUserIDs: [String],
        householdReference: DocumentReference
    ) async throws {
        let membersPerBatch = 200

        for startIndex in stride(
            from: 0,
            to: memberUserIDs.count,
            by: membersPerBatch
        ) {
            let endIndex = min(
                startIndex + membersPerBatch,
                memberUserIDs.count
            )
            let batch = database.batch()

            for memberUserID in memberUserIDs[startIndex..<endIndex] {
                batch.deleteDocument(
                    householdReference
                        .collection("members")
                        .document(memberUserID)
                )
                batch.updateData(
                    ["household_id": FieldValue.delete()],
                    forDocument: database
                        .collection("users")
                        .document(memberUserID)
                )
            }

            try await batch.commit()
        }
    }

    private func makeMember(user: UserModel, householdID: String) -> HouseholdMemberModel {
        HouseholdMemberModel(
            memberId: user.userId,
            householdId: householdID,
            userId: user.userId,
            joinedAt: .now,
            displayName: displayName(for: user),
            profileImageUrl: user.profileImageUrl
        )
    }

    private func displayName(for user: UserModel) -> String {
        let name = user.name?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let name,
           !name.isEmpty {
            return name
        }

        if let emailName = user.email?
            .split(separator: "@")
            .first {
            return String(emailName)
        }

        return "Housemate"
    }

    private func normalize(_ inviteCode: String) -> String {
        inviteCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private static func makeInviteCode() -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        return String(
            (0..<6).compactMap { _ in
                characters.randomElement()
            }
        )
    }
}
