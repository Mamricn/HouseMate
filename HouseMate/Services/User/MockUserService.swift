//
//  MockUserService.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//

import Foundation

@MainActor
final class MockUserService: UserServiceProtocol {

    private var users: [String: UserModel]

    init(
        users: [UserModel] = []
    ) {
        self.users = Dictionary(
            uniqueKeysWithValues: users.map {
                ($0.userId, $0)
            }
        )
    }

    func fetchUser(
        userID: String
    ) async throws -> UserModel? {
        users[userID]
    }

    func createUser(
        from authInfo: UserAuthInfo
    ) async throws -> UserModel {
        if let existingUser = users[authInfo.uid] {
            return existingUser
        }

        let user = UserModel(
            userId: authInfo.uid,
            createdAt: authInfo.creationDate ?? .now,
            creationVersion: appVersion,
            email: authInfo.email,
            lastSignInDate:
                authInfo.lastSignInDate ?? .now,
            name: authInfo.displayName,
            profileImageUrl:
                authInfo.profileImageURL?.absoluteString,
            householdId: nil
        )

        users[user.userId] = user

        return user
    }

    func saveUser(
        _ user: UserModel
    ) async throws {
        users[user.userId] = user
    }

    func updateHouseholdID(
        _ householdID: String?,
        for userID: String
    ) async throws {
        guard var user = users[userID] else {
            throw UserServiceError.userNotFound
        }

        user.householdId = householdID
        users[userID] = user
    }

    func deleteUserData(userID: String) async throws {
        guard users[userID] != nil else {
            throw UserServiceError.userNotFound
        }

        users[userID] = nil
    }

    private var appVersion: String? {
        Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleShortVersionString"
        ) as? String
    }
}
