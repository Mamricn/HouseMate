//
//  WelcomeView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//



import SwiftUI
import AuthenticationServices

@MainActor
struct WelcomeView: View {

    let appState: AppState

    @State private var authSheetMode: AuthSheetMode?

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                pictures

                welcomeText

                Spacer()

                buttons
            }
        }
        .ignoresSafeArea(edges: .top)
        .sheet(item: $authSheetMode) { mode in
            AuthSheetView(
                mode: mode,
                onAppleRequest: configureAppleRequest,
                onAppleCompletion: handleAppleCompletion,
                onGoogleTapped: handleGoogleSignIn
            )
            .presentationDetents([.height(450)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(32)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                .blue,
                .teal,
                .blue.opacity(0.08),
                .blue.opacity(0.002),
                .black.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var pictures: some View {
        GeometryReader { geometry in
            Image("house1")
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width * 0.8)
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.5
                )
        }
        .frame(height: 500)
    }

    private var welcomeText: some View {
        VStack(spacing: 12) {
            Text("Home life,\nmade simple.")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)

            Text(
                """
                Share bills, manage chores,
                and stay organised together.
                """
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
        }
        .padding(.horizontal, 32)
    }

    private var buttons: some View {
        VStack(spacing: 14) {
            Button {
                authSheetMode = .signUp
            } label: {
                HStack(spacing: 10) {
                    Text("Create an account")
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(
                            .system(
                                size: 14,
                                weight: .bold
                            )
                        )
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(
                            color: .blue.opacity(0.3),
                            radius: 14,
                            y: 8
                        )
                }
            }
            .buttonStyle(.plain)

            Button {
                authSheetMode = .login
            } label: {
                Text("Log in")
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule()
                                    .stroke(
                                        .white.opacity(0.7),
                                        lineWidth: 1
                                    )
                            }
                    }
            }
            .buttonStyle(.plain)

            Text(
                """
                By continuing, you agree to our \
                Terms and Privacy Policy.
                """
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
        }
        .frame(maxWidth: 340)
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
    }

    private func configureAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) {
        appState.configureAppleRequest(request)
    }

    private func handleAppleCompletion(
        _ result: Result<ASAuthorization, Error>
    ) {
        Task { @MainActor in
            await appState.signInWithApple(result)
        }
    }

    private func handleGoogleSignIn() async throws {
        try await appState.signInWithGoogle()
    }
}

#if MOCK
#Preview {
    let container = DependencyContainer.make(
        environment: .mock
    )

    let interactor = CoreInteractor(
        container: container
    )

    WelcomeView(
        appState: AppState(
            interactor: interactor
        )
    )
}
#endif
