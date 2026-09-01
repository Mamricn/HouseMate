//
//  AppState.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//




import Foundation
import AuthenticationServices

enum AppRoute {
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

    private var didBootstrap = false

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

        let authStateStream =
            interactor.authStateChanges()

        for await authUser in authStateStream {
            guard !Task.isCancelled else {
                return
            }

            await handleAuthStateChanged(authUser)
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
        do {
            errorMessage = nil
            try interactor.signOut()
        } catch {
            errorMessage = error.localizedDescription
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
        route = .main
    }

    func clearError() {
        errorMessage = nil
    }

    private func handleAuthStateChanged(
        _ authUser: UserAuthInfo?
    ) async {
        self.authUser = authUser

        guard let authUser else {
            interactor.clearCurrentHousehold()
            interactor.clearTasks()
            interactor.clearShoppingItems()
            interactor.clearBills()
            interactor.clearBoardPosts()
            interactor.clearPolls()
            interactor.clearHouseReminders()
            interactor.clearNotifications()
            currentUser = nil
            currentHousehold = nil
            householdMembers = []
            route = .welcome
            return
        }

        route = .loading

        do {
            let user: UserModel

            if let existingUser =
                try await interactor.getUser(
                    userID: authUser.uid
                ) {
                user = existingUser
            } else {
                user = try await interactor.createUser(
                    from: authUser
                )
            }

            currentUser = user

            if let householdID = user.householdId {
                guard let household = try await interactor.fetchHousehold(
                    householdID: householdID
                ) else {
                    throw AppStateError.householdNotFound
                }

                currentHousehold = household
                householdMembers = interactor.currentHouseholdMembers
                route = .main
            } else {
                currentHousehold = nil
                householdMembers = []
                route = .householdOnboarding
            }
        } catch {
            interactor.clearTasks()
            interactor.clearShoppingItems()
            interactor.clearBills()
            interactor.clearBoardPosts()
            interactor.clearPolls()
            interactor.clearHouseReminders()
            interactor.clearNotifications()
            currentUser = nil
            currentHousehold = nil
            householdMembers = []
            errorMessage = error.localizedDescription
            route = .welcome
        }
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
