//
//  HouseholdServiceProtocol.swift
//  HouseMate
//
//  Created by Marcin Turek on 26/08/2026.
//

import Foundation

@MainActor
protocol HouseholdServiceProtocol: AnyObject {

    func createHousehold(name: String, owner: UserModel) async throws -> HouseholdModel

    func joinHousehold(inviteCode: String, user: UserModel) async throws -> HouseholdModel

    func fetchHousehold(householdID: String) async throws -> HouseholdModel?

    func fetchMembers(householdID: String) async throws -> [HouseholdMemberModel]
}

enum HouseholdServiceError: LocalizedError {

    case invalidName
    case invalidInviteCode
    case householdNotFound
    case userAlreadyHasHousehold
    case unableToCreateInviteCode

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
        }
    }
}
