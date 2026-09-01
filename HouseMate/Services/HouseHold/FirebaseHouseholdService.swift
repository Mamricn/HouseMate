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

        batch.updateData(
            ["household_id": household.householdId],
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

        let snapshot = try await householdsCollection
            .whereField("invite_code", isEqualTo: normalizedCode)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            throw HouseholdServiceError.householdNotFound
        }

        var household = try Firestore.Decoder().decode(
            HouseholdModel.self,
            from: document.data()
        )

        let member = makeMember(
            user: user,
            householdID: household.householdId
        )

        let memberData = try Firestore.Encoder().encode(
            member
        )

        let memberReference = document.reference
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
            forDocument: document.reference
        )

        batch.setData(
            memberData,
            forDocument: memberReference,
            merge: true
        )

        batch.updateData(
            ["household_id": household.householdId],
            forDocument: userReference
        )

        try await batch.commit()

        if !household.memberIds.contains(user.userId) {
            household.memberIds.append(user.userId)
        }

        return household
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

        return try Firestore.Decoder().decode(
            HouseholdModel.self,
            from: data
        )
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

            let snapshot = try await householdsCollection
                .whereField("invite_code", isEqualTo: inviteCode)
                .limit(to: 1)
                .getDocuments()

            if snapshot.documents.isEmpty {
                return inviteCode
            }
        }

        throw HouseholdServiceError.unableToCreateInviteCode
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
