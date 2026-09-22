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

    private let reminder: HouseReminderModel?

    @State private var title: String
    @State private var details: String

    @State private var firstOccurrenceDate: Date
    @State private var recurrence: HouseReminderRecurrence
    @State private var category: HouseReminderCategory
    @State private var reminderAdvance: HouseReminderAdvance
    @State private var hasAttemptedSubmit = false

    init(
        reminder: HouseReminderModel? = nil,
        initialDate: Date = .now,
        onSave: @escaping (
            String,
            String?,
            Date,
            HouseReminderRecurrence,
            HouseReminderCategory,
            HouseReminderAdvance
        ) -> Void
    ) {
        self.reminder = reminder
        self.onSave = onSave
        _title = State(initialValue: reminder?.title ?? "")
        _details = State(initialValue: reminder?.details ?? "")
        _firstOccurrenceDate = State(initialValue: reminder?.firstOccurrenceDate ?? initialDate)
        _recurrence = State(initialValue: reminder?.recurrence ?? .never)
        _category = State(initialValue: reminder?.category ?? .other)
        _reminderAdvance = State(initialValue: reminder?.reminderAdvance ?? .none)
    }

    var body: some View {
        NavigationStack {
            Form {
                informationSection
                categorySection
                scheduleSection
                notificationSection
            }
            .navigationTitle(reminder == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancellationToolbar
                confirmationToolbar
            }
        }
        .onAppear {
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

            if hasAttemptedSubmit && trimmedTitle.isEmpty {
                FormValidationMessage(message: "Enter a reminder title.")
            }

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
            if reminder == nil {
                DatePicker(
                    "First Date",
                    selection: $firstOccurrenceDate,
                    in: startOfToday...,
                    displayedComponents: .date
                )
            } else {
                DatePicker(
                    "First Date",
                    selection: $firstOccurrenceDate,
                    displayedComponents: .date
                )
            }

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
            Text("HouseMate will ask for notification permission when you add a reminder with notifications enabled.")
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
            Button(reminder == nil ? "Add" : "Save") {
                saveReminder()
            }
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
        hasAttemptedSubmit = true

        guard !trimmedTitle.isEmpty else {
            HapticFeedback.validationError()
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
