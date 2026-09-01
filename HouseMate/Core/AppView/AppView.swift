//
//  AppView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//


import SwiftUI

@MainActor
struct AppView: View {

    @State private var appState: AppState
    private let interactor: CoreInteractor

    init() {
        let container = DependencyContainer.make()
        let interactor = CoreInteractor(
            container: container
        )

        self.interactor = interactor

        _appState = State(
            initialValue: AppState(
                interactor: interactor
            )
        )
    }

    init(
        container: DependencyContainer
    ) {
        let interactor = CoreInteractor(
            container: container
        )

        self.interactor = interactor

        _appState = State(
            initialValue: AppState(
                interactor: interactor
            )
        )
    }

    var body: some View {
        ZStack {
            screenContent
        }
        .animation(
            .smooth,
            value: appState.route
        )
        .task {
            await appState.bootstrap()
        }
        .alert(
            "Something went wrong",
            isPresented: errorBinding
        ) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(
                appState.errorMessage
                    ?? "Please try again."
            )
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch appState.route {
        case .loading:
            loadingView
                .transition(.opacity)

        case .welcome:
            WelcomeView(
                appState: appState
            )

        case .householdOnboarding:
            if let currentUser = appState.currentUser {
                SelectView(
                    viewModel: SelectViewModel(
                        interactor: interactor,
                        user: currentUser,
                        onHouseholdCompleted: { household in
                            appState.completeHouseholdOnboarding(
                                with: household
                            )
                        }
                    )
                )
                .transition(
                    .move(edge: .trailing)
                        .combined(with: .opacity)
                )
            } else {
                loadingView
                    .transition(.opacity)
            }

        case .main:
            if let currentUser = appState.currentUser,
               let currentHousehold = appState.currentHousehold {
                TabbarView(
                    user: currentUser,
                    household: currentHousehold,
                    members: appState.householdMembers,
                    interactor: interactor,
                    onSignOut: {
                        appState.signOut()
                    }
                )
                .transition(
                    .move(edge: .trailing)
                        .combined(with: .opacity)
                )
            } else {
                loadingView
                    .transition(.opacity)
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .blue,
                    .teal,
                    .blue.opacity(0.08),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(
                        .system(
                            size: 34,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
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
                    }

                ProgressView()
                    .controlSize(.large)

                Text("Preparing your home...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: {
                appState.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    appState.clearError()
                }
            }
        )
    }
}

#if MOCK
#Preview {
    AppView()
}
#endif
