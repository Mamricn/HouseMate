//
//  UserAuthInfo.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import Foundation

enum AuthProvider: String, Sendable {
    case apple
    case google
    case unknown
}

struct UserAuthInfo: Equatable, Sendable {

    let uid: String
    let email: String?
    let displayName: String?
    let profileImageURL: URL?
    let creationDate: Date?
    let lastSignInDate: Date?
    let provider: AuthProvider

    init(
        uid: String,
        email: String? = nil,
        displayName: String? = nil,
        profileImageURL: URL? = nil,
        creationDate: Date? = nil,
        lastSignInDate: Date? = nil,
        provider: AuthProvider = .unknown
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.creationDate = creationDate
        self.lastSignInDate = lastSignInDate
        self.provider = provider
    }
}

struct AuthSignInResult: Equatable, Sendable {

    let user: UserAuthInfo
    let isNewUser: Bool

    init(
        user: UserAuthInfo,
        isNewUser: Bool
    ) {
        self.user = user
        self.isNewUser = isNewUser
    }
}

extension UserAuthInfo {

    static let mock = UserAuthInfo(
        uid: "mock_user_123",
        email: "marcin@email.com",
        displayName: "Marcin",
        profileImageURL: nil,
        creationDate: .now,
        lastSignInDate: .now,
        provider: .google
    )
}

extension AuthSignInResult {

    static let mock = AuthSignInResult(
        user: .mock,
        isNewUser: false
    )
}
