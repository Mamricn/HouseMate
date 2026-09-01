//
//  HouseholdManager.swift
//  HouseMate
//
//  Created by Marcin Turek on 26/08/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class HouseholdManager {

    private let householdService:
        any HouseholdServiceProtocol

    private let userService:
        any UserServiceProtocol

    private(set) var currentHousehold:
        HouseholdModel?

    private(set) var currentMembers: [HouseholdMemberModel] = []

    init(householdService: any HouseholdServiceProtocol, userService: any UserServiceProtocol) {
        self.householdService = householdService
        self.userService = userService
    }

    @discardableResult
    func createHousehold(name: String, owner: UserModel) async throws -> HouseholdModel {
        let household = try await householdService
            .createHousehold(
                name: name,
                owner: owner
            )

        try await userService.updateHouseholdID(
            household.householdId,
            for: owner.userId
        )

        currentHousehold = household
        currentMembers = await membersAfterOnboarding(
            householdID: household.householdId,
            fallbackUser: owner
        )

        return household
    }

    @discardableResult
    func joinHousehold(inviteCode: String, user: UserModel) async throws -> HouseholdModel {
        let household = try await householdService
            .joinHousehold(
                inviteCode: inviteCode,
                user: user
            )

        try await userService.updateHouseholdID(
            household.householdId,
            for: user.userId
        )

        currentHousehold = household
        currentMembers = await membersAfterOnboarding(
            householdID: household.householdId,
            fallbackUser: user
        )

        return household
    }

    @discardableResult
    func fetchHousehold(householdID: String) async throws -> HouseholdModel? {
        let household = try await householdService
            .fetchHousehold(
                householdID: householdID
            )

        currentHousehold = household

        if household != nil {
            currentMembers = try await householdService.fetchMembers(
                householdID: householdID
            )
        } else {
            currentMembers = []
        }

        return household
    }

    func clearCurrentHousehold() {
        currentHousehold = nil
        currentMembers = []
    }

    private func membersAfterOnboarding(householdID: String, fallbackUser: UserModel) async -> [HouseholdMemberModel] {
        do {
            let members = try await householdService.fetchMembers(
                householdID: householdID
            )

            if !members.isEmpty {
                return members
            }
        } catch {
            // Household creation/join already succeeded. Keep the signed-in
            // user available until the next full refresh instead of failing
            // the completed onboarding transaction.
        }

        return [
            HouseholdMemberModel(
                memberId: fallbackUser.userId,
                householdId: householdID,
                userId: fallbackUser.userId,
                joinedAt: .now,
                displayName: fallbackUser.name ?? "Housemate",
                profileImageUrl: fallbackUser.profileImageUrl
            )
        ]
    }
}
