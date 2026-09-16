//
//  SettingsView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI
import UIKit

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let user: UserModel
    let household: HouseholdModel?
    let onSignOut: () -> Void
    var onManageHousehold: () -> Void = {}
    var onManageAccount: () -> Void = {}
    var onManageProfile: () -> Void = {}
    var onNotificationPreferencesChanged: () async -> Void = {}
    var onSendTestNotification: () async -> Bool = { false }
    var onAutomaticWeeklyAssignmentChanged: (Bool) async -> Bool = { _ in false }
    var onRunWeeklyAssignmentNow: () async -> Bool = { false }

#if DEVELOPMENT
    @State private var isSendingTestNotification = false
    @State private var isRunningWeeklyAssignment = false
    @State private var weeklyAssignmentResult: String?
#endif

    @State private var automaticWeeklyAssignment = false
    @State private var isUpdatingAutomaticAssignment = false

    @AppStorage("taskNotificationsEnabled")
    private var taskNotificationsEnabled = true

    @AppStorage("houseReminderNotificationsEnabled")
    private var houseReminderNotificationsEnabled = true

    @AppStorage("billNotificationsEnabled")
    private var billNotificationsEnabled = true

    var body: some View {
        Form {
            profileSection
            householdSection
            notificationsSection
            aboutSection
            accountSection
        }
        .scrollContentBackground(.hidden)
        .background {
            settingsBackground
                .ignoresSafeArea()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .confirmationAction
            ) {
                Button("Done") {
                    dismiss()
                }
            }
        }
#if DEVELOPMENT
        .alert(
            "Weekly Assignment",
            isPresented: Binding(
                get: { weeklyAssignmentResult != nil },
                set: { if !$0 { weeklyAssignmentResult = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(weeklyAssignmentResult ?? "")
        }
#endif
    }

    private var settingsBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.95, blue: 1.00),
                    Color(red: 0.95, green: 0.89, blue: 0.98),
                    Color(red: 0.91, green: 0.96, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 48)
                .offset(x: 170, y: -300)

            Circle()
                .fill(Color.purple.opacity(0.10))
                .frame(width: 250, height: 250)
                .blur(radius: 45)
                .offset(x: -170, y: 280)
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section("Profile") {
            Button {
                onManageProfile()
            } label: {
                HStack(spacing: 14) {
                    profileImage

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name ?? "Unknown User")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if let email = user.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(settingsRowBackground)
    }

    private var profileImage: some View {
        CachedProfileImage(
            urlString: user.profileImageUrl,
            displayName: user.name ?? "Housemate",
            size: 54
        )
    }

    // MARK: - Household

    private var householdSection: some View {
        Section {
            Button {
                onManageHousehold()
            } label: {
                HStack {
                    Text("Manage Household")
                        .foregroundStyle(.black)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if canManageAutomaticAssignment {
                Toggle(
                    "Automatic Weekly Assignment",
                    isOn: Binding(
                        get: { automaticWeeklyAssignment },
                        set: { updateAutomaticWeeklyAssignment(to: $0) }
                    )
                )
                .disabled(isUpdatingAutomaticAssignment)

#if DEVELOPMENT
                Button {
                    runWeeklyAssignmentNow()
                } label: {
                    if isRunningWeeklyAssignment {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Run Weekly Assignment Now")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!automaticWeeklyAssignment || isRunningWeeklyAssignment)
#endif
            }
        } header: {
            Text("Household")
        } footer: {
            if canManageAutomaticAssignment {
                Text(
                    automaticWeeklyAssignment
                    ? "Chores will be fairly rotated between housemates each week."
                    : "Chores are assigned manually."
                )
            }
        }
        .task {
            automaticWeeklyAssignment = household?.automaticWeeklyAssignmentEnabled ?? false
        }
        .listRowBackground(settingsRowBackground)
    }

    private var canManageAutomaticAssignment: Bool {
        guard let household else { return false }
        return household.isOwner(userID: user.userId)
    }

    private func updateAutomaticWeeklyAssignment(to isEnabled: Bool) {
        let previousValue = automaticWeeklyAssignment
        automaticWeeklyAssignment = isEnabled
        isUpdatingAutomaticAssignment = true

        Task {
            let didSave = await onAutomaticWeeklyAssignmentChanged(isEnabled)
            if !didSave {
                automaticWeeklyAssignment = previousValue
            }
            isUpdatingAutomaticAssignment = false
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(
                "Task Notifications",
                isOn: $taskNotificationsEnabled
            )

            Toggle(
                "House Reminders",
                isOn: $houseReminderNotificationsEnabled
            )

            Toggle(
                "Bill Notifications",
                isOn: $billNotificationsEnabled
            )

            Button {
                openNotificationSettings()
            } label: {
                HStack {
                    Text("System Permission")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("Open Settings")
                        .foregroundStyle(.blue)

                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

#if DEVELOPMENT
            Button {
                sendTestNotification()
            } label: {
                if isSendingTestNotification {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Send Test Notification").frame(maxWidth: .infinity)
                }
            }
            .disabled(isSendingTestNotification)
#endif
        }
        .onChange(of: taskNotificationsEnabled) { _, _ in updateNotificationPreferences() }
        .onChange(of: houseReminderNotificationsEnabled) { _, _ in updateNotificationPreferences() }
        .onChange(of: billNotificationsEnabled) { _, _ in updateNotificationPreferences() }
        .listRowBackground(settingsRowBackground)
    }

    private func updateNotificationPreferences() {
        Task { await onNotificationPreferencesChanged() }
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }

        openURL(url)
    }

#if DEVELOPMENT
    private func sendTestNotification() {
        isSendingTestNotification = true

        Task {
            _ = await onSendTestNotification()
            isSendingTestNotification = false
        }
    }

    private func runWeeklyAssignmentNow() {
        isRunningWeeklyAssignment = true

        Task {
            let didStart = await onRunWeeklyAssignmentNow()
            weeklyAssignmentResult = didStart
                ? "The rotation command was sent. Changes will appear shortly."
                : "The rotation could not be started. Please try again."
            isRunningWeeklyAssignment = false
        }
    }
#endif

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("App Version")

                Spacer()

                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            LabeledContent(
                "Household",
                value: user.householdId ?? "Not joined"
            )
        }
        .listRowBackground(settingsRowBackground)
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("Account") {
            Button {
                onManageAccount()
            } label: {
                HStack {
                    Text("Account Settings")
                        .foregroundStyle(.black)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                dismiss()
                onSignOut()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.blue)

                    Text("Sign Out")
                        .foregroundStyle(.primary)
                }
            }
        }
        .listRowBackground(settingsRowBackground)
    }

    private var settingsRowBackground: some View {
        Color.white.opacity(0.48)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String ?? "1.0"
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        user: UserModel.mockList[0],
        household: .mock,
        onSignOut: {}
    )
}
