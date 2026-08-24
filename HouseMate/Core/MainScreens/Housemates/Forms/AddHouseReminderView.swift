//
//  AddHouseReminderView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//



import SwiftUI

struct AddHouseReminderView: View {

    @Environment(\.dismiss) private var dismiss

    let onSave: (
        _ title: String,
        _ details: String?,
        _ firstOccurrenceDate: Date,
        _ recurrence: HouseReminderRecurrence,
        _ category: HouseReminderCategory,
        _ reminderAdvance: HouseReminderAdvance
    ) -> Void

    @State private var title = ""
    @State private var details = ""

    @State private var firstOccurrenceDate = Date.now
    @State private var recurrence: HouseReminderRecurrence = .never
    @State private var category: HouseReminderCategory = .other
    @State private var reminderAdvance: HouseReminderAdvance = .none

    var body: some View {
        NavigationStack {
            Form {
                informationSection
                categorySection
                scheduleSection
                notificationSection
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancellationToolbar
                confirmationToolbar
            }
        }
    }

    // MARK: - Information

    private var informationSection: some View {
        Section("Information") {
            TextField(
                "Title",
                text: $title
            )
            .textInputAutocapitalization(.sentences)

            TextField(
                "Details (optional)",
                text: $details,
                axis: .vertical
            )
            .lineLimit(3...6)
            .textInputAutocapitalization(.sentences)
        }
    }

    // MARK: - Category

    private var categorySection: some View {
        Section("Category") {
            Picker(
                "Category",
                selection: $category
            ) {
                ForEach(
                    HouseReminderCategory.allCases,
                    id: \.self
                ) { category in
                    Label(
                        category.title,
                        systemImage: category.systemImage
                    )
                    .tag(category)
                }
            }
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        Section("Schedule") {
            DatePicker(
                "First Date",
                selection: $firstOccurrenceDate,
                in: startOfToday...,
                displayedComponents: .date
            )

            Picker(
                "Repeats",
                selection: $recurrence
            ) {
                ForEach(
                    HouseReminderRecurrence.allCases,
                    id: \.self
                ) { recurrence in
                    Text(recurrence.title)
                        .tag(recurrence)
                }
            }
        }
    }

    // MARK: - Notification

    private var notificationSection: some View {
        Section {
            Picker(
                "Notify",
                selection: $reminderAdvance
            ) {
                ForEach(
                    HouseReminderAdvance.allCases,
                    id: \.self
                ) { advance in
                    Text(advance.title)
                        .tag(advance)
                }
            }
        } header: {
            Text("Notification")
        } footer: {
            Text(
                "Notifications will be enabled " +
                "after Firebase and local notifications are connected."
            )
        }
    }

    // MARK: - Toolbar

    private var cancellationToolbar: some ToolbarContent {
        ToolbarItem(
            placement: .cancellationAction
        ) {
            Button("Cancel") {
                dismiss()
            }
        }
    }

    private var confirmationToolbar: some ToolbarContent {
        ToolbarItem(
            placement: .confirmationAction
        ) {
            Button("Add") {
                saveReminder()
            }
            .disabled(trimmedTitle.isEmpty)
        }
    }

    // MARK: - Values

    private var trimmedTitle: String {
        title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var trimmedDetails: String? {
        let value = details.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return value.isEmpty ? nil : value
    }

    private var startOfToday: Date {
        Calendar.autoupdatingCurrent.startOfDay(
            for: .now
        )
    }

    // MARK: - Save

    private func saveReminder() {
        guard !trimmedTitle.isEmpty else {
            return
        }

        onSave(
            trimmedTitle,
            trimmedDetails,
            firstOccurrenceDate,
            recurrence,
            category,
            reminderAdvance
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddHouseReminderView {
        title,
        details,
        firstDate,
        recurrence,
        category,
        advance in

        print(title)
        print(details as Any)
        print(firstDate)
        print(recurrence)
        print(category)
        print(advance)
    }
}
