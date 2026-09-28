import SwiftUI
import UIKit

struct AddHousemateView: View {

    @Environment(\.dismiss) private var dismiss

    let household: HouseholdModel
    var ensureInviteLookup: () async throws -> Void = {}

    @State private var didCopyCode = false
    @State private var inviteErrorMessage: String?
    @State private var invitePreparationState = InvitePreparationState.loading

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    invitationHeader
                    inviteCodeCard
                    sharingActions
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Invite Housemate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            do {
                try await ensureInviteLookup()
                invitePreparationState = .ready
            } catch {
                invitePreparationState = .failed
                inviteErrorMessage = error.localizedDescription
            }
        }
        .alert(
            "Invitation could not be prepared",
            isPresented: Binding(
                get: { inviteErrorMessage != nil },
                set: { if !$0 { inviteErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(inviteErrorMessage ?? "Please try again.")
        }
    }

    private var invitationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )

            Text("Invite someone to \(household.name)")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Share the code below with someone you trust.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            preparationStatus
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var preparationStatus: some View {
        switch invitePreparationState {
        case .loading:
            Label("Preparing invitation…", systemImage: "arrow.trianglehead.2.clockwise")
                .foregroundStyle(.secondary)

        case .ready:
            Label("Invitation ready", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .failed:
            Label("Invitation unavailable", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var inviteCodeCard: some View {
        VStack(spacing: 14) {
            Text("INVITE CODE")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(household.inviteCode)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .tracking(6)
                .foregroundStyle(.blue)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Button {
                copyInviteCode()
            } label: {
                Label(
                    didCopyCode ? "Code Copied" : "Copy Code",
                    systemImage: didCopyCode ? "checkmark" : "doc.on.doc"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(didCopyCode ? .green : .blue)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(cardBackground)
    }

    private var sharingActions: some View {
        ShareLink(
            item: inviteMessage,
            subject: Text("Join my household on HouseMate")
        ) {
            Label("Share Invitation", systemImage: "square.and.arrow.up")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.blue, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.background)
            .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
    }

    private var inviteMessage: String {
        let url = AppEnvironment.current.invitationURL(
            inviteCode: household.inviteCode
        )?.absoluteString ?? "housemate://join/\(household.inviteCode)"

        return "You're invited to join \(household.name) on HouseMate: \(url) (invite code: \(household.inviteCode))."
    }

    private func copyInviteCode() {
        UIPasteboard.general.string = household.inviteCode
        HapticFeedback.actionSuccess()

        withAnimation(.smooth) {
            didCopyCode = true
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.smooth) {
                didCopyCode = false
            }
        }
    }
}

private enum InvitePreparationState {
    case loading
    case ready
    case failed
}

#Preview {
    AddHousemateView(household: .mock)
}
