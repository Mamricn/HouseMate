//
//  MockAuthServiceTests.swift
//  HouseMateTests
//

import Testing
@testable import HouseMate

@Suite("MockAuthService — sign-in and session state")
@MainActor
struct MockAuthServiceTests {

    @Test("Google sign-in stores the signed-in user")
    func googleSignInStoresCurrentUser() async throws {
        let service = MockAuthService()

        let result = try await service.signInWithGoogle()

        #expect(result.user.uid == UserAuthInfo.mock.uid)
        #expect(service.currentUser?.uid == UserAuthInfo.mock.uid)
    }

    @Test("Sign-out clears the user and publishes the signed-out state")
    func signOutPublishesSignedOutState() async throws {
        let service = MockAuthService(currentUser: .mock)
        let states = service.authStateChanges()

        try service.signOut()

        var iterator = states.makeAsyncIterator()
        let initialState = await iterator.next()
        let signedOutState = await iterator.next()

        #expect(initialState??.uid == UserAuthInfo.mock.uid)
        #expect(signedOutState != nil)
        #expect(signedOutState! == nil)
        #expect(service.currentUser == nil)
    }

    @Test("Reauthentication fails when there is no signed-in user")
    func reauthenticationRequiresCurrentUser() async {
        let service = MockAuthService()

        do {
            try await service.reauthenticateWithGoogle()
            Issue.record("Reauthentication should fail without a signed-in user.")
        } catch let error as AuthServiceError {
            guard case .missingCurrentUser = error else {
                Issue.record("Expected missingCurrentUser, received \(error).")
                return
            }
        } catch {
            Issue.record("Expected AuthServiceError, received \(error).")
        }
    }
}
