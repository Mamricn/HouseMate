//
//  UserServiceProtocol.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import Foundation

@MainActor
protocol UserServiceProtocol: AnyObject {

    func fetchUser(
        userID: String
    ) async throws -> UserModel?

    func createUser(
        from authInfo: UserAuthInfo
    ) async throws -> UserModel

    func saveUser(
        _ user: UserModel
    ) async throws

    func updateHouseholdID(
        _ householdID: String?,
        for userID: String
    ) async throws
}


enum UserServiceError: LocalizedError {

    case userNotFound

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "The user profile could not be found."
        }
    }
}
