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
    @State private var deepLinkCoordinator = DeepLinkCoordinator.shared
    private let interactor: CoreInteractor
    private let screenAnalyticsTracker: ScreenAnalyticsTracker

    init() {
        StartupDiagnostics.mark("AppView init started")
        let container = DependencyContainer.make()
        let interactor = CoreInteractor(
            container: container
        )

        self.interactor = interactor
        self.screenAnalyticsTracker = ScreenAnalyticsTracker(
            logService: container.logService
        )

        _appState = State(
            initialValue: AppState(
                interactor: interactor
            )
        )
        StartupDiagnostics.mark("AppView init finished")
    }

    init(
        container: DependencyContainer
    ) {
        let interactor = CoreInteractor(
            container: container
        )

        self.interactor = interactor
        self.screenAnalyticsTracker = ScreenAnalyticsTracker(
            logService: container.logService
        )

        _appState = State(
            initialValue: AppState(
                interactor: interactor
            )
        )
    }

    var body: some View {
        screenContent
        .animation(
            .smooth,
            value: appState.route
        )
        .task {
            // Let the first frame reach the display before auth/Firebase work starts.
            await Task.yield()
            StartupDiagnostics.mark("AppView bootstrap task started")
            await appState.bootstrap()
        }
        .onOpenURL { url in
            deepLinkCoordinator.handle(url: url)
        }
        .environment(\.screenAnalyticsTracker, screenAnalyticsTracker)
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
                    ),
                    pendingDeepLink: deepLinkCoordinator.pending,
                    onDeepLinkHandled: deepLinkCoordinator.consume
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
                    },
                    onProfileImageChanged: { imageURL in
                        appState.updateProfileImageURL(imageURL)
                    },
                    deepLinkCoordinator: deepLinkCoordinator
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

private extension AppRoute {
    var analyticsName: String {
        switch self {
        case .loading: "preparing_home"
        case .welcome: "welcome"
        case .householdOnboarding: "household_onboarding"
        case .main: "home"
        }
    }
}

#if MOCK
#Preview {
    AppView()
}
#endif
