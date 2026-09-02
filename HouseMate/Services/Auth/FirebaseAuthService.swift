//
//  FirebaseAuthService.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

@MainActor
final class FirebaseAuthService: AuthServiceProtocol {

    private(set) var currentUser: UserAuthInfo?

    private var currentAppleNonce: String?

    private var authStateContinuation:
        AsyncStream<UserAuthInfo?>.Continuation?

    init() {
        currentUser = Auth.auth().currentUser.map {
            UserAuthInfo(firebaseUser: $0)
        }
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
        let nonce = Self.randomNonceString()

        currentAppleNonce = nonce

        request.requestedScopes = [
            .fullName,
            .email
        ]

        request.nonce = Self.sha256(nonce)
    }

    func signInWithApple(
        _ result: Result<ASAuthorization, Error>
    ) async throws -> AuthSignInResult {
        let authorization = try result.get()

        guard let appleCredential =
                authorization.credential
                    as? ASAuthorizationAppleIDCredential
        else {
            throw AuthServiceError.missingAppleCredential
        }

        guard let nonce = currentAppleNonce else {
            throw AuthServiceError.missingAppleNonce
        }

        guard let identityToken =
                appleCredential.identityToken
        else {
            throw AuthServiceError.missingAppleIdentityToken
        }

        guard let identityTokenString = String(
            data: identityToken,
            encoding: .utf8
        ) else {
            throw AuthServiceError.invalidAppleIdentityToken
        }

        let firebaseCredential =
            OAuthProvider.appleCredential(
                withIDToken: identityTokenString,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )

        let firebaseResult = try await Auth.auth().signIn(
            with: firebaseCredential
        )

        currentAppleNonce = nil

        return completeSignIn(
            firebaseResult: firebaseResult
        )
    }

    func signInWithGoogle() async throws -> AuthSignInResult {
        let firebaseCredential = try await googleCredential()

        let firebaseResult = try await Auth.auth().signIn(
            with: firebaseCredential
        )

        return completeSignIn(
            firebaseResult: firebaseResult
        )
    }

    func reauthenticateWithApple(
        _ result: Result<ASAuthorization, Error>
    ) async throws {
        let credential = try appleCredential(from: result)

        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.missingCurrentUser
        }

        try await user.reauthenticate(with: credential)
        currentAppleNonce = nil
    }

    func reauthenticateWithGoogle() async throws {
        let credential = try await googleCredential()

        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.missingCurrentUser
        }

        try await user.reauthenticate(with: credential)
    }

    func deleteCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.missingCurrentUser
        }

        try await user.delete()
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        notifyAuthStateChanged()
    }

    private func googleCredential() async throws -> AuthCredential {
        guard let clientID =
                FirebaseApp.app()?.options.clientID
        else {
            throw AuthServiceError.firebaseNotConfigured
        }

        guard let presentingViewController =
                UIApplication.shared
                    .activeRootViewController
        else {
            throw AuthServiceError
                .missingPresentingViewController
        }

        GIDSignIn.sharedInstance.configuration =
            GIDConfiguration(clientID: clientID)

        let googleResult = try await GIDSignIn
            .sharedInstance
            .signIn(
                withPresenting: presentingViewController
            )

        guard let idToken =
                googleResult.user.idToken?.tokenString
        else {
            throw AuthServiceError.missingGoogleIDToken
        }

        let accessToken =
            googleResult.user.accessToken.tokenString

        return GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
    }

    private func appleCredential(
        from result: Result<ASAuthorization, Error>
    ) throws -> AuthCredential {
        let authorization = try result.get()

        guard let appleCredential = authorization.credential
            as? ASAuthorizationAppleIDCredential
        else {
            throw AuthServiceError.missingAppleCredential
        }

        guard let nonce = currentAppleNonce else {
            throw AuthServiceError.missingAppleNonce
        }

        guard let identityToken = appleCredential.identityToken else {
            throw AuthServiceError.missingAppleIdentityToken
        }

        guard let identityTokenString = String(
            data: identityToken,
            encoding: .utf8
        ) else {
            throw AuthServiceError.invalidAppleIdentityToken
        }

        return OAuthProvider.appleCredential(
            withIDToken: identityTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
    }

    func signOut() throws {
        try Auth.auth().signOut()

        GIDSignIn.sharedInstance.signOut()

        currentUser = nil
        notifyAuthStateChanged()
    }

    private func completeSignIn(
        firebaseResult: AuthDataResult
    ) -> AuthSignInResult {
        let user = UserAuthInfo(
            firebaseUser: firebaseResult.user
        )

        let result = AuthSignInResult(
            user: user,
            isNewUser:
                firebaseResult.additionalUserInfo?
                    .isNewUser ?? false
        )

        currentUser = user
        notifyAuthStateChanged()

        return result
    }

    private func notifyAuthStateChanged() {
        authStateContinuation?.yield(currentUser)
    }

    private static func sha256(
        _ input: String
    ) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)

        return hashedData
            .map {
                String(format: "%02x", $0)
            }
            .joined()
    }

    private static func randomNonceString(
        length: Int = 32
    ) -> String {
        precondition(length > 0)

        var randomBytes = [
            UInt8
        ](
            repeating: 0,
            count: length
        )

        let errorCode = SecRandomCopyBytes(
            kSecRandomDefault,
            randomBytes.count,
            &randomBytes
        )

        guard errorCode == errSecSuccess else {
            fatalError(
                """
                Unable to generate Apple Sign-In nonce. \
                OSStatus: \(errorCode)
                """
            )
        }

        let characters = Array(
            """
            0123456789ABCDEFGHIJKLMNOPQRSTUVXYZ\
            abcdefghijklmnopqrstuvwxyz-._
            """
        )

        return String(
            randomBytes.map { byte in
                characters[
                    Int(byte) % characters.count
                ]
            }
        )
    }
}

private extension UserAuthInfo {

    init(firebaseUser: FirebaseAuth.User) {
        self.init(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            profileImageURL: firebaseUser.photoURL,
            creationDate:
                firebaseUser.metadata.creationDate,
            lastSignInDate:
                firebaseUser.metadata.lastSignInDate,
            provider: firebaseUser.authProvider
        )
    }
}

private extension FirebaseAuth.User {

    var authProvider: AuthProvider {
        if providerData.contains(where: {
            $0.providerID == "apple.com"
        }) {
            return .apple
        }

        if providerData.contains(where: {
            $0.providerID == "google.com"
        }) {
            return .google
        }

        return .unknown
    }
}

private extension UIApplication {

    var activeRootViewController: UIViewController? {
        let activeScene = connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .first {
                $0.activationState == .foregroundActive
            }

        guard let rootViewController = activeScene?
            .windows
            .first(where: \.isKeyWindow)?
            .rootViewController
        else {
            return nil
        }

        return topViewController(
            from: rootViewController
        )
    }

    func topViewController(
        from viewController: UIViewController
    ) -> UIViewController {
        if let presentedViewController =
                viewController.presentedViewController {
            return topViewController(
                from: presentedViewController
            )
        }

        if let navigationController =
                viewController as? UINavigationController,
           let visibleViewController =
                navigationController.visibleViewController {
            return topViewController(
                from: visibleViewController
            )
        }

        if let tabBarController =
                viewController as? UITabBarController,
           let selectedViewController =
                tabBarController.selectedViewController {
            return topViewController(
                from: selectedViewController
            )
        }

        return viewController
    }
}
