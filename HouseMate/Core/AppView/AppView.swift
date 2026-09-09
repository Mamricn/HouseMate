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
    @State private var showsAnimatedLaunch = true
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

            if showsAnimatedLaunch {
                AnimatedLaunchView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(
            .smooth,
            value: appState.route
        )
        .task {
            await appState.bootstrap()
        }
        .task {
            try? await Task.sleep(for: .seconds(1.55))

            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.35)) {
                showsAnimatedLaunch = false
            }
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
                    },
                    onHouseholdLeft: {
                        appState.completeHouseholdExit()
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
        PreparingHomeView()
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
