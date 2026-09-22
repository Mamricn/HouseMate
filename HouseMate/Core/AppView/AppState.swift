//
//  AppState.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//




import Foundation
import AuthenticationServices

enum AppRoute: Equatable {
    case loading
    case welcome
    case householdOnboarding
    case main
}

@MainActor
@Observable
final class AppState {

    private(set) var route: AppRoute = .loading

    private(set) var authUser: UserAuthInfo?
    private(set) var currentUser: UserModel?
    private(set) var currentHousehold: HouseholdModel?
    private(set) var householdMembers: [HouseholdMemberModel] = []

    private(set) var errorMessage: String?

    private let interactor: CoreInteractor
    private let startupCache = StartupSessionCache()

    private var didBootstrap = false
    private var authObservationTask: Task<Void, Never>?

    init(
        interactor: CoreInteractor
    ) {
        self.interactor = interactor
    }

    func bootstrap() async {
        guard !didBootstrap else {
            return
        }

        didBootstrap = true
        route = .loading
        StartupDiagnostics.mark("Bootstrap started")

        let authStartedAt = StartupDiagnostics.begin(
            "Auth state restore"
        )
        let initialAuthUser = interactor.currentAuthUser
        StartupDiagnostics.end(
            "Auth state restore",
            startedAt: authStartedAt
        )

        await handleAuthStateChanged(initialAuthUser)

        startObservingAuthChanges()
        StartupDiagnostics.mark("Bootstrap finished")
    }

    private func startObservingAuthChanges() {
        authObservationTask?.cancel()

        let authStateStream = interactor.authStateChanges()
        authObservationTask = Task { @MainActor [weak self] in
            for await authUser in authStateStream {
                guard !Task.isCancelled, let self else { return }

                if authUser?.uid == self.authUser?.uid {
                    continue
                }

                await self.handleAuthStateChanged(authUser)
            }
        }
    }

    func configureAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) {
        interactor.configureAppleRequest(request)
    }

    func signInWithApple(
        _ result: Result<ASAuthorization, Error>
    ) async {
        do {
            errorMessage = nil

            _ = try await interactor.signInWithApple(
                result
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async throws {
        errorMessage = nil

        do {
            _ = try await interactor.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func signOut() {
        Task {
            errorMessage = nil

            if let userID = currentUser?.id {
                await interactor.unregisterRemoteNotifications(
                    userID: userID
                )
            }

            do {
                try interactor.signOut()
                interactor.resetAnalyticsUser()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func completeHouseholdOnboarding(with household: HouseholdModel) {
        guard var currentUser else {
            return
        }

        currentUser.householdId = household.householdId
        self.currentUser = currentUser
        currentHousehold = household
        householdMembers = interactor.currentHouseholdMembers
        startupCache.save(
            user: currentUser,
            household: household,
            members: householdMembers
        )
        route = .main
    }

    func completeHouseholdExit() {
        guard var currentUser else { return }

        currentUser.householdId = nil
        self.currentUser = currentUser
        currentHousehold = nil
        householdMembers = []
        startupCache.clear()
        clearHouseholdData()
        route = .householdOnboarding
    }

    func updateProfileImageURL(_ imageURL: String?) {
        guard var currentUser else { return }

        currentUser.profileImageUrl = imageURL
        self.currentUser = currentUser

        for index in householdMembers.indices
            where householdMembers[index].userId == currentUser.id {
            householdMembers[index].profileImageUrl = imageURL
        }

        guard let currentHousehold else { return }
        startupCache.save(
            user: currentUser,
            household: currentHousehold,
            members: householdMembers
        )
    }

    func clearError() {
        errorMessage = nil
    }

    private func handleAuthStateChanged(
        _ authUser: UserAuthInfo?
    ) async {
        self.authUser = authUser
        StartupDiagnostics.mark(
            authUser == nil ? "Auth user is signed out" : "Auth user restored"
        )

        guard let authUser else {
            interactor.resetAnalyticsUser()
            startupCache.clear()
            clearHouseholdData()
            currentUser = nil
            currentHousehold = nil
            householdMembers = []
            route = .welcome
            return
        }

        let cacheStartedAt = StartupDiagnostics.begin("Startup session cache")
        let cachedSession = startupCache.session(for: authUser.uid)
        StartupDiagnostics.end(
            "Startup session cache",
            startedAt: cacheStartedAt
        )

        if let cachedSession {
            currentUser = cachedSession.user
            interactor.identifyAnalyticsUser(
                userID: cachedSession.user.id
            )
            currentHousehold = cachedSession.household
            householdMembers = cachedSession.members
            route = .main
            StartupDiagnostics.mark("Main route shown from cache")

            Task { @MainActor [interactor] in
                await Task.yield()
                interactor.restoreCachedHousehold(
                    cachedSession.household,
                    members: cachedSession.members
                )
            }

            // Do not perform blocking Firestore document reads during launch.
            // Feature data and household members refresh through listeners.
            return
        } else {
            route = .loading
            StartupDiagnostics.mark("No startup cache; waiting for Firebase")
        }

        do {
            let user: UserModel

            let userStartedAt = StartupDiagnostics.begin("User fetch")
            if let existingUser =
                try await interactor.getUser(
                    userID: authUser.uid
                ) {
                user = existingUser
            } else {
                do {
                    user = try await interactor.createUser(from: authUser)
                } catch {
                    throw error
                }
            }
            StartupDiagnostics.end("User fetch", startedAt: userStartedAt)

            currentUser = user
            interactor.identifyAnalyticsUser(userID: user.id)

            if let householdID = user.householdId {
                let householdStartedAt = StartupDiagnostics.begin(
                    "Household and members fetch"
                )
                guard let household = try await interactor.fetchHousehold(
                    householdID: householdID
                ) else {
                    throw AppStateError.householdNotFound
                }
                StartupDiagnostics.end(
                    "Household and members fetch",
                    startedAt: householdStartedAt
                )

                currentHousehold = household
                householdMembers = interactor.currentHouseholdMembers
                startupCache.save(
                    user: user,
                    household: household,
                    members: householdMembers
                )
                route = .main
                StartupDiagnostics.mark("Main route shown after Firebase")
            } else {
                startupCache.clear()
                currentHousehold = nil
                householdMembers = []
                route = .householdOnboarding
            }
        } catch {
            StartupDiagnostics.mark(
                "Bootstrap refresh failed: \(error.localizedDescription)"
            )
            if cachedSession != nil {
                // Keep the last known-good session visible when a refresh is
                // slow or temporarily unavailable.
                return
            }

            clearHouseholdData()
            currentUser = nil
            currentHousehold = nil
            householdMembers = []
            errorMessage = error.localizedDescription
            route = .welcome
        }
    }

    private func clearHouseholdData() {
        interactor.clearCurrentHousehold()
        interactor.clearTasks()
        interactor.clearShoppingItems()
        interactor.clearBills()
        interactor.clearBoardPosts()
        interactor.clearPolls()
        interactor.clearHouseReminders()
        interactor.clearHouseholdDocuments()
        interactor.clearNotifications()
    }
}

private struct CachedStartupSession: Codable {
    let user: UserModel
    let household: HouseholdModel
    let members: [HouseholdMemberModel]
}

@MainActor
private final class StartupSessionCache {

    private let defaults: UserDefaults
    private let key = "housemate.startup-session.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func session(for userID: String) -> CachedStartupSession? {
        guard let data = defaults.data(forKey: key),
              let session = try? JSONDecoder().decode(
                CachedStartupSession.self,
                from: data
              ),
              session.user.id == userID,
              session.user.householdId == session.household.id else {
            return nil
        }

        return session
    }

    func save(
        user: UserModel,
        household: HouseholdModel,
        members: [HouseholdMemberModel]
    ) {
        let session = CachedStartupSession(
            user: user,
            household: household,
            members: members
        )

        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

enum AppStateError: LocalizedError {
    case householdNotFound

    var errorDescription: String? {
        switch self {
        case .householdNotFound:
            return "Your household could not be found."
        }
    }
}
