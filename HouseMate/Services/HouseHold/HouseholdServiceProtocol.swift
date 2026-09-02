//
//  HouseholdServiceProtocol.swift
//  HouseMate
//
//  Created by Marcin Turek on 26/08/2026.
//

import Foundation

@MainActor
protocol HouseholdServiceProtocol: AnyObject {

    var updatesUserHouseholdAtomically: Bool { get }

    func createHousehold(name: String, owner: UserModel) async throws -> HouseholdModel

    func joinHousehold(inviteCode: String, user: UserModel) async throws -> HouseholdModel

    func fetchHousehold(householdID: String) async throws -> HouseholdModel?

    func fetchMembers(householdID: String) async throws -> [HouseholdMemberModel]

    func removeMember(
        householdID: String,
        memberUserID: String,
        requestedByUserID: String
    ) async throws

    func transferOwnership(
        householdID: String,
        newOwnerUserID: String,
        requestedByUserID: String
    ) async throws

    func leaveHousehold(
        householdID: String,
        userID: String
    ) async throws

    func deleteHousehold(
        householdID: String,
        requestedByUserID: String
    ) async throws

    func observeMembers(
        householdID: String,
        onChange: @escaping (Result<[HouseholdMemberModel], Error>) -> Void
    ) -> ServiceObservation?
}

extension HouseholdServiceProtocol {

    var updatesUserHouseholdAtomically: Bool {
        false
    }

    func observeMembers(
        householdID: String,
        onChange: @escaping (Result<[HouseholdMemberModel], Error>) -> Void
    ) -> ServiceObservation? {
        nil
    }
}

enum HouseholdServiceError: LocalizedError {

    case invalidName
    case invalidInviteCode
    case householdNotFound
    case userAlreadyHasHousehold
    case unableToCreateInviteCode
    case ownerPermissionRequired
    case ownerCannotBeRemoved
    case memberNotFound
    case ownershipTransferRequired

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Please enter a valid home name."

        case .invalidInviteCode:
            return "Please enter a valid invite code."

        case .householdNotFound:
            return "We couldn't find a home with this invite code."

        case .userAlreadyHasHousehold:
            return "You already belong to a home."

        case .unableToCreateInviteCode:
            return "We couldn't create an invite code. Please try again."

        case .ownerPermissionRequired:
            return "Only the household owner can remove members."

        case .ownerCannotBeRemoved:
            return "The household owner cannot be removed."

        case .memberNotFound:
            return "This person is no longer a member of the household."

        case .ownershipTransferRequired:
            return "Transfer ownership before leaving this household."
        }
    }
}
