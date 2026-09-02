//
//  MockHouseholdService.swift
//  HouseMate
//
//  Created by Marcin Turek on 26/08/2026.
//

import Foundation

@MainActor
final class MockHouseholdService: HouseholdServiceProtocol {

    private var households: [String: HouseholdModel]
    private var membersByHouseholdID: [String: [String: HouseholdMemberModel]]

    init(households: [HouseholdModel] = [], members: [HouseholdMemberModel] = []) {
        self.households = Dictionary(
            uniqueKeysWithValues: households.map {
                ($0.householdId, $0)
            }
        )

        self.membersByHouseholdID = Dictionary(
            grouping: members,
            by: \.householdId
        )
        .mapValues { householdMembers in
            Dictionary(
                uniqueKeysWithValues: householdMembers.map {
                    ($0.userId, $0)
                }
            )
        }
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

        let household = HouseholdModel(
            householdId: UUID().uuidString,
            createdAt: .now,
            name: normalizedName,
            inviteCode: makeUniqueInviteCode(),
            createdByUserId: owner.userId,
            memberIds: [owner.userId]
        )

        households[household.householdId] = household
        membersByHouseholdID[household.householdId] = [
            owner.userId: makeMember(
                user: owner,
                householdID: household.householdId
            )
        ]

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

        guard let entry = households.first(where: {
            $0.value.inviteCode == normalizedCode
        }) else {
            throw HouseholdServiceError.householdNotFound
        }

        var household = entry.value

        if !household.memberIds.contains(user.userId) {
            household.memberIds.append(user.userId)
            households[entry.key] = household
        }

        membersByHouseholdID[household.householdId, default: [:]][user.userId] = makeMember(
            user: user,
            householdID: household.householdId
        )

        return household
    }

    func fetchHousehold(householdID: String) async throws -> HouseholdModel? {
        households[householdID]
    }

    func fetchMembers(householdID: String) async throws -> [HouseholdMemberModel] {
        Array(membersByHouseholdID[householdID, default: [:]].values)
            .sorted {
                ($0.joinedAt ?? .distantPast) < ($1.joinedAt ?? .distantPast)
            }
    }

    func removeMember(
        householdID: String,
        memberUserID: String,
        requestedByUserID: String
    ) async throws {
        guard var household = households[householdID] else {
            throw HouseholdServiceError.householdNotFound
        }

        guard household.isOwner(userID: requestedByUserID) else {
            throw HouseholdServiceError.ownerPermissionRequired
        }

        guard memberUserID != household.ownerUserId else {
            throw HouseholdServiceError.ownerCannotBeRemoved
        }

        guard household.memberIds.contains(memberUserID) else {
            throw HouseholdServiceError.memberNotFound
        }

        household.memberIds.removeAll { $0 == memberUserID }
        households[householdID] = household
        membersByHouseholdID[householdID]?[memberUserID] = nil
    }

    func transferOwnership(
        householdID: String,
        newOwnerUserID: String,
        requestedByUserID: String
    ) async throws {
        guard var household = households[householdID] else {
            throw HouseholdServiceError.householdNotFound
        }

        guard household.isOwner(userID: requestedByUserID) else {
            throw HouseholdServiceError.ownerPermissionRequired
        }

        guard newOwnerUserID != requestedByUserID,
              household.memberIds.contains(newOwnerUserID)
        else {
            throw HouseholdServiceError.memberNotFound
        }

        household.ownerUserId = newOwnerUserID
        households[householdID] = household
    }

    func leaveHousehold(
        householdID: String,
        userID: String
    ) async throws {
        guard var household = households[householdID] else {
            throw HouseholdServiceError.householdNotFound
        }

        guard !household.isOwner(userID: userID) else {
            throw HouseholdServiceError.ownershipTransferRequired
        }

        guard household.memberIds.contains(userID) else {
            throw HouseholdServiceError.memberNotFound
        }

        household.memberIds.removeAll { $0 == userID }
        households[householdID] = household
        membersByHouseholdID[householdID]?[userID] = nil
    }

    func deleteHousehold(
        householdID: String,
        requestedByUserID: String
    ) async throws {
        guard let household = households[householdID] else {
            throw HouseholdServiceError.householdNotFound
        }

        guard household.isOwner(userID: requestedByUserID) else {
            throw HouseholdServiceError.ownerPermissionRequired
        }

        households[householdID] = nil
        membersByHouseholdID[householdID] = nil
    }

    private func makeUniqueInviteCode() -> String {
        var inviteCode = Self.makeInviteCode()

        while households.values.contains(where: {
            $0.inviteCode == inviteCode
        }) {
            inviteCode = Self.makeInviteCode()
        }

        return inviteCode
    }

    private func normalize(_ inviteCode: String) -> String {
        inviteCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
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
        let name = user.name?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let name, !name.isEmpty {
            return name
        }

        if let emailName = user.email?.split(separator: "@").first {
            return String(emailName)
        }

        return "Housemate"
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
