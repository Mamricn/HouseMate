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

    private var membersObservation: ServiceObservation?

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

        if !householdService.updatesUserHouseholdAtomically {
            try await userService.updateHouseholdID(
                household.householdId,
                for: owner.userId
            )
        }

        currentHousehold = household
        startObservingMembers(householdID: household.householdId)
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

        if !householdService.updatesUserHouseholdAtomically {
            try await userService.updateHouseholdID(
                household.householdId,
                for: user.userId
            )
        }

        currentHousehold = household
        startObservingMembers(householdID: household.householdId)
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
            startObservingMembers(householdID: householdID)
            currentMembers = try await householdService.fetchMembers(
                householdID: householdID
            )
        } else {
            membersObservation?.cancel()
            membersObservation = nil
            currentMembers = []
        }

        return household
    }

    func clearCurrentHousehold() {
        membersObservation?.cancel()
        membersObservation = nil
        currentHousehold = nil
        currentMembers = []
    }

    private func startObservingMembers(householdID: String) {
        membersObservation?.cancel()
        membersObservation = householdService.observeMembers(
            householdID: householdID
        ) { [weak self] result in
            guard case .success(let members) = result else {
                return
            }

            self?.currentMembers = members
        }
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
