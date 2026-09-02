//
//  MockAuthService.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//


import Foundation
import AuthenticationServices

@MainActor
final class MockAuthService: AuthServiceProtocol {

    private(set) var currentUser: UserAuthInfo?

    private var authStateContinuation:
        AsyncStream<UserAuthInfo?>.Continuation?

    init(
        currentUser: UserAuthInfo? = nil
    ) {
        self.currentUser = currentUser
    }

    deinit {
        authStateContinuation?.finish()
    }

    func authStateChanges() -> AsyncStream<UserAuthInfo?> {
        let stream = AsyncStream.makeStream(
            of: UserAuthInfo?.self
        )

        authStateContinuation?.finish()
        authStateContinuation = stream.continuation

        stream.continuation.yield(currentUser)

        return stream.stream
    }

    func configureAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) {
        request.requestedScopes = [
            .fullName,
            .email
        ]
    }

    func signInWithApple(
        _ result: Result<ASAuthorization, Error>
    ) async throws -> AuthSignInResult {
        _ = try result.get()

        return signInMockUser()
    }

    func signInWithGoogle() async throws -> AuthSignInResult {
        signInMockUser()
    }

    func signOut() throws {
        currentUser = nil
        notifyAuthStateChanged()
    }

    func reauthenticateWithApple(
        _ result: Result<ASAuthorization, Error>
    ) async throws {
        _ = try result.get()
    }

    func reauthenticateWithGoogle() async throws {
        guard currentUser != nil else {
            throw AuthServiceError.missingCurrentUser
        }
    }

    func deleteCurrentUser() async throws {
        guard currentUser != nil else {
            throw AuthServiceError.missingCurrentUser
        }

        currentUser = nil
        notifyAuthStateChanged()
    }

    @discardableResult
    private func signInMockUser() -> AuthSignInResult {
        let result = AuthSignInResult(
            user: .mock,
            isNewUser: false
        )

        currentUser = result.user
        notifyAuthStateChanged()

        return result
    }

    private func notifyAuthStateChanged() {
        authStateContinuation?.yield(currentUser)
    }
}
