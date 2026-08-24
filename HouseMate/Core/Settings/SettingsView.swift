//
//  SettingsView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    let user: UserModel

    @AppStorage("automaticWeeklyAssignment")
    private var automaticWeeklyAssignment = false

    @AppStorage("taskNotificationsEnabled")
    private var taskNotificationsEnabled = true

    @AppStorage("houseReminderNotificationsEnabled")
    private var houseReminderNotificationsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                householdSection
                notificationsSection
                aboutSection
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
        }
    }

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

    private var appVersion: String {
        Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String ?? "1.0"
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        user: UserModel.mockList[0]
    )
}
