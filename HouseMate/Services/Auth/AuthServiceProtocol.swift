//
//  AuthServiceProtocol.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import Foundation
import AuthenticationServices

@MainActor
protocol AuthServiceProtocol: AnyObject {

    var currentUser: UserAuthInfo? { get }

    func authStateChanges() -> AsyncStream<UserAuthInfo?>

    func configureAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    )

    func signInWithApple(
        _ result: Result<ASAuthorization, Error>
    ) async throws -> AuthSignInResult

    func signInWithGoogle() async throws -> AuthSignInResult

    func signOut() throws
}



enum AuthServiceError: LocalizedError {

    case firebaseNotConfigured
    case missingPresentingViewController

    case missingAppleCredential
    case missingAppleIdentityToken
    case missingAppleNonce
    case invalidAppleIdentityToken

    case missingGoogleIDToken

    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase is not configured."

        case .missingPresentingViewController:
            return "Unable to present the Google sign-in screen."

        case .missingAppleCredential:
            return "The Apple credential is unavailable."

        case .missingAppleIdentityToken:
            return "Apple did not return an identity token."

        case .missingAppleNonce:
            return "The Apple sign-in request is invalid."

        case .invalidAppleIdentityToken:
            return "The Apple identity token could not be read."

        case .missingGoogleIDToken:
            return "Google did not return an identity token."
        }
    }
}
