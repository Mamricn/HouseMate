//
//  AccountSettingsView.swift
//  HouseMate
//

import SwiftUI
import AuthenticationServices

enum AccountDeletionMode: String, Identifiable {
    case accountOnly
    case householdAndAccount

    var id: String { rawValue }
}

@MainActor
@Observable
final class AccountSettingsViewModel {

    let user: UserModel
    let household: HouseholdModel?
    let actionState = AsyncActionState()

    private let interactor: CoreInteractor

    var isHouseholdOwner: Bool {
        household?.isOwner(userID: user.id) == true
    }

    var authProvider: AuthProvider {
        interactor.currentAuthProvider
    }

    var isSoleHouseholdOwner: Bool {
        guard isHouseholdOwner else { return false }

        let storedOtherMemberIDs = household?.memberIds.filter {
            $0 != user.id
        } ?? []
        let observedOtherMembers = interactor.currentHouseholdMembers.filter {
            $0.userId != user.id
        }

        return storedOtherMemberIDs.isEmpty
            && observedOtherMembers.isEmpty
    }

    init(
        user: UserModel,
        household: HouseholdModel?,
        interactor: CoreInteractor
    ) {
        self.user = user
        self.household = household
        self.interactor = interactor
    }

    func configureAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) {
        interactor.configureAppleRequest(request)
    }

    func deleteWithApple(
        _ result: Result<ASAuthorization, Error>,
        mode: AccountDeletionMode
    ) async -> Bool {
        await actionState.perform {
            try await interactor.reauthenticateWithApple(result)
            try await deleteAccount(mode: mode)
        }
    }

    func deleteWithGoogle(
        mode: AccountDeletionMode
    ) async -> Bool {
        await actionState.perform {
            try await interactor.reauthenticateWithGoogle()
            try await deleteAccount(mode: mode)
        }
    }

    private func deleteAccount(
        mode: AccountDeletionMode
    ) async throws {
        switch mode {
        case .accountOnly:
            guard !isHouseholdOwner else {
                throw HouseholdServiceError.ownershipTransferRequired
            }

            if interactor.currentHousehold != nil {
                try await interactor.leaveHousehold(userID: user.id)
            }

        case .householdAndAccount:
            guard isSoleHouseholdOwner else {
                throw HouseholdServiceError.ownershipTransferRequired
            }

            if interactor.currentHousehold != nil {
                try await interactor.deleteHousehold(
                    requestedByUserID: user.id
                )
            }
        }

        try await interactor.deleteUserData(userID: user.id)
        try await interactor.deleteCurrentAuthUser()
    }
}

struct AccountSettingsView: View {

    let viewModel: AccountSettingsViewModel
    var onManageHousehold: () -> Void = {}
    var onAccountDeleted: () -> Void = {}

    @State private var deletionMode: AccountDeletionMode?

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 20) {
                    accountCard
                    deleteCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $deletionMode) { mode in
            DeleteAccountConfirmationView(
                viewModel: viewModel,
                mode: mode,
                onDeleted: {
                    deletionMode = nil
                    onAccountDeleted()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(
                viewModel.actionState.isLoading
            )
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                .blue.opacity(0.14),
                .purple.opacity(0.09),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var accountCard: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.user.name ?? "Housemate")
                    .font(.title3.bold())

                if let email = viewModel.user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(cardBackground)
    }

    @ViewBuilder
    private var deleteCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Delete Account", systemImage: "trash.fill")
                .font(.headline)
                .foregroundStyle(.red)

            if viewModel.isHouseholdOwner {
                if viewModel.isSoleHouseholdOwner {
                    Text(
                        "You are the only member. HouseMate can permanently delete the household and your account together."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Button {
                        deletionMode = .householdAndAccount
                    } label: {
                        Text("Delete Household and Account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(.red, in: Capsule())
                } else {
                    Text(
                        "Before deleting your account, transfer ownership to another housemate or delete the household."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Button {
                        onManageHousehold()
                    } label: {
                        Text("Manage Household")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(.blue, in: Capsule())
                }
            } else {
                Text(
                    "Your profile, notifications and account will be permanently deleted. This cannot be undone."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button {
                    deletionMode = .accountOnly
                } label: {
                    Text("Delete Account")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.red, in: Capsule())
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 14, y: 7)
    }
}

private struct DeleteAccountConfirmationView: View {

    @Environment(\.dismiss) private var dismiss

    let viewModel: AccountSettingsViewModel
    let mode: AccountDeletionMode
    let onDeleted: () -> Void

    @State private var confirmationText = ""
    @State private var hasAttemptedDelete = false
    @State private var isReadyForReauthentication = false
    @FocusState private var isConfirmationFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                warningHeader
                confirmationField
                reauthenticationButton
                Spacer()
            }
            .padding(20)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.actionState.isLoading)
                }
            }
            .alert(
                "Unable to delete account",
                isPresented: errorBinding
            ) {
                Button("OK") {
                    viewModel.actionState.clearError()
                }
            } message: {
                Text(
                    viewModel.actionState.errorMessage
                        ?? "Please try again."
                )
            }
        }
    }

    private var warningHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 5) {
                Text("This cannot be undone")
                    .font(.headline)

                Text(
                    warningMessage
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var confirmationField: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Type DELETE to confirm.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("DELETE", text: $confirmationText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isConfirmationFocused)
                .padding(13)
                .background(
                    .quaternary,
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )

            if hasAttemptedDelete && !isConfirmationValid {
                FormValidationMessage(
                    message: "Enter DELETE exactly as shown."
                )
            }
        }
    }

    @ViewBuilder
    private var reauthenticationButton: some View {
        if viewModel.actionState.isLoading {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.white)
                Text("Deleting Account...")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(.red, in: Capsule())
        } else if !isReadyForReauthentication {
            Button {
                guard validateConfirmation() else { return }
                isConfirmationFocused = false
                isReadyForReauthentication = true
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.red, in: Capsule())
            }
            .buttonStyle(.plain)
        } else {
            switch viewModel.authProvider {
            case .apple:
                SignInWithAppleButton(.continue) { request in
                    viewModel.configureAppleRequest(request)
                } onCompletion: { result in
                    Task {
                        if await viewModel.deleteWithApple(
                            result,
                            mode: mode
                        ) {
                            onDeleted()
                        }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(Capsule())

            case .google, .unknown:
                Button {
                    guard validateConfirmation() else { return }

                    Task {
                        if await viewModel.deleteWithGoogle(
                            mode: mode
                        ) {
                            onDeleted()
                        }
                    }
                } label: {
                    Text("Continue with Google")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.red, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var isConfirmationValid: Bool {
        confirmationText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) == "DELETE"
    }

    private var navigationTitle: String {
        switch mode {
        case .accountOnly:
            return "Delete Account"
        case .householdAndAccount:
            return "Delete Everything"
        }
    }

    private var warningMessage: String {
        switch mode {
        case .accountOnly:
            return "You will be asked to sign in again before HouseMate permanently deletes your account."
        case .householdAndAccount:
            return "Your household, all shared data and your account will be permanently deleted after you sign in again."
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: {
                viewModel.actionState.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.actionState.clearError()
                }
            }
        )
    }

    private func validateConfirmation() -> Bool {
        hasAttemptedDelete = true

        guard isConfirmationValid else {
            HapticFeedback.validationError()
            isConfirmationFocused = true
            return false
        }

        return true
    }
}
