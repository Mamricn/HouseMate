import SwiftUI
import UIKit

struct AddHousemateView: View {

    @Environment(\.dismiss) private var dismiss

    let household: HouseholdModel

    @State private var didCopyCode = false

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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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
        "You're invited to join \(household.name) on HouseMate: https://housemate-5fbc5.web.app/join/\(household.inviteCode) (invite code: \(household.inviteCode))."
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

#Preview {
    AddHousemateView(household: .mock)
}
