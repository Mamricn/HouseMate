//
//  AuthSheetView.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//




import SwiftUI
import AuthenticationServices

enum AuthSheetMode: String, Identifiable {

    case signUp
    case login

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .signUp:
            return "Create your account"

        case .login:
            return "Welcome back"
        }
    }

    var subtitle: String {
        switch self {
        case .signUp:
            return "Choose how you want to join HouseMate."

        case .login:
            return "Choose how you want to continue."
        }
    }
}

struct AuthSheetView: View {

    let mode: AuthSheetMode

    let onAppleRequest: (
        ASAuthorizationAppleIDRequest
    ) -> Void

    let onAppleCompletion: (
        Result<ASAuthorization, Error>
    ) -> Void

    let onGoogleTapped: () async throws -> Void

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        ZStack {
            background

            VStack(spacing: 24) {
                header

                authenticationButtons

                footer

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 28)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                .blue.opacity(0.14),
                .teal.opacity(0.08),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(
                            .system(
                                size: 13,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Image(systemName: "house.fill")
                .font(
                    .system(
                        size: 26,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .blue,
                                    .cyan
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: .blue.opacity(0.25),
                            radius: 12,
                            y: 6
                        )
                }

            VStack(spacing: 8) {
                Text(mode.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var authenticationButtons: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(
                .signIn,
                onRequest: onAppleRequest,
                onCompletion: onAppleCompletion
            )
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )

            SignInWithGoogleButton(
                colorScheme: .white
            ) {
                try await onGoogleTapped()
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Text(
                """
                If you already have an account, \
                we'll sign you in.
                """
            )

            Text(
                """
                By continuing, you agree to our \
                Terms and Privacy Policy.
                """
            )
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    AuthSheetView(
        mode: .signUp,
        onAppleRequest: { request in
            request.requestedScopes = [
                .fullName,
                .email
            ]
        },
        onAppleCompletion: { _ in },
        onGoogleTapped: {}
    )
}
