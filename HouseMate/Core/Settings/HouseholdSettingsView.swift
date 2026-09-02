//
//  HouseholdSettingsView.swift
//  HouseMate
//

import SwiftUI

@MainActor
@Observable
final class HouseholdSettingsViewModel {

    private(set) var household: HouseholdModel
    let currentUser: UserModel
    let actionState = AsyncActionState()

    private let interactor: CoreInteractor

    var members: [HouseholdMemberModel] {
        interactor.currentHouseholdMembers
    }

    var isCurrentUserOwner: Bool {
        household.isOwner(userID: currentUser.id)
    }

    var ownershipCandidates: [HouseholdMemberModel] {
        members.filter { $0.userId != currentUser.id }
    }

    init(
        household: HouseholdModel,
        currentUser: UserModel,
        interactor: CoreInteractor
    ) {
        self.household = household
        self.currentUser = currentUser
        self.interactor = interactor
    }

    func canRemove(_ member: HouseholdMemberModel) -> Bool {
        isCurrentUserOwner
            && member.userId != currentUser.id
            && member.userId != household.ownerUserId
    }

    func remove(_ member: HouseholdMemberModel) async -> Bool {
        guard canRemove(member) else {
            return false
        }

        return await actionState.perform {
            try await interactor.removeHouseholdMember(
                userID: member.userId,
                requestedByUserID: currentUser.id
            )
        }
    }

    func transferOwnership(
        to member: HouseholdMemberModel
    ) async -> Bool {
        guard isCurrentUserOwner,
              member.userId != currentUser.id
        else {
            return false
        }

        let didTransfer = await actionState.perform {
            try await interactor.transferHouseholdOwnership(
                to: member.userId,
                requestedByUserID: currentUser.id
            )
        }

        if didTransfer {
            household.ownerUserId = member.userId
        }

        return didTransfer
    }

    func leaveHousehold() async -> Bool {
        guard !isCurrentUserOwner else {
            return false
        }

        return await actionState.perform {
            try await interactor.leaveHousehold(
                userID: currentUser.id
            )
        }
    }

    func deleteHousehold() async -> Bool {
        guard isCurrentUserOwner else {
            return false
        }

        return await actionState.perform {
            try await interactor.deleteHousehold(
                requestedByUserID: currentUser.id
            )
        }
    }
}

private enum HouseholdConfirmation: Identifiable {
    case remove(HouseholdMemberModel)
    case transfer(HouseholdMemberModel)
    case leave

    var id: String {
        switch self {
        case .remove(let member):
            return "remove-\(member.userId)"
        case .transfer(let member):
            return "transfer-\(member.userId)"
        case .leave:
            return "leave"
        }
    }
}

struct HouseholdSettingsView: View {

    let viewModel: HouseholdSettingsViewModel
    var onHouseholdLeft: () -> Void = {}

    @State private var confirmation: HouseholdConfirmation?
    @State private var showsOwnershipPicker = false
    @State private var showsDeleteHousehold = false
    @State private var toast: AppToast?

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 20) {
                    householdCard
                    inviteCard
                    membersCard
                    managementCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Household")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsOwnershipPicker) {
            ownershipPicker
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsDeleteHousehold) {
            DeleteHouseholdConfirmationView(
                viewModel: viewModel,
                onDeleted: {
                    showsDeleteHousehold = false
                    onHouseholdLeft()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert(item: $confirmation) { confirmation in
            confirmationAlert(confirmation)
        }
        .alert(
            "Something went wrong",
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
        .overlay(alignment: .top) {
            if let toast {
                AppToastView(toast: toast)
                    .padding(.top, 12)
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Household

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                .blue.opacity(0.16),
                .purple.opacity(0.10),
                .cyan.opacity(0.08),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var householdCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background {
                    RoundedRectangle(
                        cornerRadius: 19,
                        style: .continuous
                    )
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .shadow(
                    color: .blue.opacity(0.25),
                    radius: 10,
                    y: 5
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.household.name)
                    .font(.title2.bold())
                    .lineLimit(2)

                Label(
                    membersCountText,
                    systemImage: "person.2.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Invitation

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invite a housemate")
                    .font(.headline)

                Text("Share this code with someone you trust.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.household.inviteCode)
                .font(
                    .system(
                        size: 30,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .tracking(5)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .fill(.blue.opacity(0.08))
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                        .stroke(
                            .blue.opacity(0.16),
                            lineWidth: 1
                        )
                    }
                }

            ShareLink(
                item: inviteMessage,
                subject: Text("Join my household on HouseMate")
            ) {
                Label("Add Member", systemImage: "person.badge.plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background {
                        Capsule()
                            .fill(.blue)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Members

    private var membersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Household Members")
                    .font(.title3.bold())

                Spacer()

                Text("\(viewModel.members.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: Capsule())
            }

            if viewModel.members.isEmpty {
                ContentUnavailableView(
                    "No Household Members",
                    systemImage: "person.3"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(
                        Array(viewModel.members.enumerated()),
                        id: \.element.id
                    ) { index, member in
                        memberRow(member)

                        if index < viewModel.members.count - 1 {
                            Divider()
                                .padding(.leading, 58)
                        }
                    }
                }
            }

            if viewModel.isCurrentUserOwner {
                Text(
                    "Removing a housemate removes their membership and disconnects their account from this household."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Management

    @ViewBuilder
    private var managementCard: some View {
        if viewModel.isCurrentUserOwner {
            VStack(alignment: .leading, spacing: 14) {
                Text("Household Management")
                    .font(.headline)

                Button {
                    showsOwnershipPicker = true
                } label: {
                    managementButtonLabel(
                        title: "Transfer Ownership",
                        subtitle: "Choose another housemate to manage this home",
                        systemImage: "arrow.left.arrow.right",
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
                .disabled(
                    viewModel.ownershipCandidates.isEmpty
                        || viewModel.actionState.isLoading
                )

                if viewModel.ownershipCandidates.isEmpty {
                    Text("Invite another housemate before transferring ownership.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Button {
                    showsDeleteHousehold = true
                } label: {
                    managementButtonLabel(
                        title: "Delete Household",
                        subtitle: "Permanently delete this home and all shared data",
                        systemImage: "trash.fill",
                        color: .red
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.actionState.isLoading)
            }
            .padding(20)
            .background(cardBackground)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text("Membership")
                    .font(.headline)

                Button {
                    confirmation = .leave
                } label: {
                    managementButtonLabel(
                        title: "Leave Household",
                        subtitle: "Remove your account from this home",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        color: .red
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.actionState.isLoading)
            }
            .padding(20)
            .background(cardBackground)
        }
    }

    private func managementButtonLabel(
        title: String,
        subtitle: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(color)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func memberRow(
        _ member: HouseholdMemberModel
    ) -> some View {
        HStack(spacing: 12) {
            memberAvatar(member)

            VStack(alignment: .leading, spacing: 3) {
                Text(member.displayName)
                    .font(.body.weight(.medium))

                if member.userId == viewModel.currentUser.id {
                    Text("You")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if viewModel.canRemove(member) {
                Button {
                    confirmation = .remove(member)
                } label: {
                    Image(systemName: "person.fill.xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(width: 38, height: 38)
                        .background(.red.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.actionState.isLoading)
                .accessibilityLabel("Remove \(member.displayName)")
            }
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func memberAvatar(
        _ member: HouseholdMemberModel
    ) -> some View {
        if let profileImageUrl = member.profileImageUrl,
           let url = URL(string: profileImageUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                avatarFallback(member)
            }
            .frame(width: 46, height: 46)
            .clipShape(Circle())
        } else {
            avatarFallback(member)
        }
    }

    private func avatarFallback(
        _ member: HouseholdMemberModel
    ) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.85), .purple.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 46, height: 46)
            .overlay {
                Text(memberInitials(member))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
    }

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 26,
            style: .continuous
        )
        .fill(.ultraThinMaterial)
        .overlay {
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
            .stroke(.white.opacity(0.45), lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(0.06),
            radius: 14,
            y: 7
        )
    }

    private var membersCountText: String {
        let count = viewModel.members.count
        return count == 1 ? "1 member" : "\(count) members"
    }

    private func memberInitials(
        _ member: HouseholdMemberModel
    ) -> String {
        let initials = member.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)

        return initials.isEmpty
            ? "?"
            : String(initials).uppercased()
    }

    private var ownershipPicker: some View {
        NavigationStack {
            List(viewModel.ownershipCandidates) { member in
                Button {
                    selectNewOwner(member)
                } label: {
                    HStack(spacing: 12) {
                        memberAvatar(member)

                        Text(member.displayName)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Choose New Owner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showsOwnershipPicker = false
                    }
                }
            }
        }
    }

    private func confirmationAlert(
        _ confirmation: HouseholdConfirmation
    ) -> Alert {
        switch confirmation {
        case .remove(let member):
            return Alert(
                title: Text("Remove housemate?"),
                message: Text(
                    "\(member.displayName) will lose access to this household and its shared data."
                ),
                primaryButton: .destructive(
                    Text("Remove")
                ) {
                    remove(member)
                },
                secondaryButton: .cancel()
            )

        case .transfer(let member):
            return Alert(
                title: Text("Transfer ownership?"),
                message: Text(
                    "\(member.displayName) will be able to manage members and the household."
                ),
                primaryButton: .default(
                    Text("Transfer")
                ) {
                    transferOwnership(to: member)
                },
                secondaryButton: .cancel()
            )

        case .leave:
            return Alert(
                title: Text("Leave household?"),
                message: Text(
                    "You will lose access to this household and its shared data."
                ),
                primaryButton: .destructive(
                    Text("Leave Household")
                ) {
                    leaveHousehold()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func selectNewOwner(
        _ member: HouseholdMemberModel
    ) {
        showsOwnershipPicker = false

        Task {
            try? await Task.sleep(for: .milliseconds(350))
            confirmation = .transfer(member)
        }
    }

    private var inviteMessage: String {
        "Join \(viewModel.household.name) on HouseMate using invite code \(viewModel.household.inviteCode)."
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

    private func remove(_ member: HouseholdMemberModel) {
        Task {
            let didRemove = await viewModel.remove(member)

            guard didRemove else { return }

            withAnimation(.smooth) {
                toast = AppToast(
                    message: "\(member.displayName) removed",
                    systemImage: "person.fill.xmark",
                    color: .green
                )
            }

            try? await Task.sleep(for: .seconds(2))

            withAnimation(.smooth) {
                toast = nil
            }
        }
    }

    private func transferOwnership(
        to member: HouseholdMemberModel
    ) {
        Task {
            let didTransfer = await viewModel.transferOwnership(
                to: member
            )

            guard didTransfer else { return }

            showToast(
                message: "Ownership transferred to \(member.displayName)",
                systemImage: "checkmark.shield.fill"
            )
        }
    }

    private func leaveHousehold() {
        Task {
            let didLeave = await viewModel.leaveHousehold()

            guard didLeave else { return }

            onHouseholdLeft()
        }
    }

    private func showToast(
        message: String,
        systemImage: String
    ) {
        withAnimation(.smooth) {
            toast = AppToast(
                message: message,
                systemImage: systemImage,
                color: .green
            )
        }

        Task {
            try? await Task.sleep(for: .seconds(2))

            withAnimation(.smooth) {
                toast = nil
            }
        }
    }
}

private struct DeleteHouseholdConfirmationView: View {

    @Environment(\.dismiss) private var dismiss

    let viewModel: HouseholdSettingsViewModel
    let onDeleted: () -> Void

    @State private var householdName = ""
    @State private var hasAttemptedDelete = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                warningHeader

                VStack(alignment: .leading, spacing: 9) {
                    Text(
                        "Type \(viewModel.household.name) to confirm."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    TextField(
                        "Household name",
                        text: $householdName
                    )
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isNameFocused)
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
                            message: "Enter the exact household name."
                        )
                    }
                }

                Button {
                    deleteHousehold()
                } label: {
                    Group {
                        if viewModel.actionState.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Delete Household")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.red, in: Capsule())
                .disabled(viewModel.actionState.isLoading)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Delete Household")
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
                "Unable to delete household",
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
                    "Tasks, bills, shopping items, reminders, polls, posts and memberships will be permanently deleted."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var isConfirmationValid: Bool {
        householdName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) == viewModel.household.name
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

    private func deleteHousehold() {
        hasAttemptedDelete = true

        guard isConfirmationValid else {
            HapticFeedback.validationError()
            isNameFocused = true
            return
        }

        Task {
            let didDelete = await viewModel.deleteHousehold()

            guard didDelete else { return }
            onDeleted()
        }
    }
}
