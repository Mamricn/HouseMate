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
    let onSignOut: () -> Void
    var onManageHousehold: () -> Void = {}
    var onManageAccount: () -> Void = {}
    var onNotificationPreferencesChanged: () async -> Void = {}
    var onSendTestNotification: () async -> Bool = { false }

#if DEVELOPMENT
    @State private var isSendingTestNotification = false
#endif

    @AppStorage("automaticWeeklyAssignment")
    private var automaticWeeklyAssignment = false

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
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section("Profile") {
            HStack(spacing: 14) {
                profileImage

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name ?? "Unknown User")
                        .font(.headline)

                    if let email = user.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var profileImage: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue,
                            Color.purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "person.fill")
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 54, height: 54)
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

            Toggle(
                "Automatic Weekly Assignment",
                isOn: $automaticWeeklyAssignment
            )
        } header: {
            Text("Household")
        } footer: {
            Text(
                automaticWeeklyAssignment
                    ? "Chores will be fairly rotated between housemates each week."
                    : "Chores are assigned manually."
            )
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
        onSignOut: {}
    )
}
