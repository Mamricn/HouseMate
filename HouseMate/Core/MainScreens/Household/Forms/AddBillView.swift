//
//  AddBillView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//

import SwiftUI

struct AddBillView: View {

    @Environment(\.dismiss) private var dismiss

    let onSave: (
        _ title: String,
        _ amount: Double,
        _ dueDate: Date,
        _ category: BillCategory,
        _ isRecurring: Bool,
        _ recurrence: BillRecurrence?,
        _ notificationAdvance: HouseReminderAdvance
    ) -> Void

    @State private var title = ""
    @State private var amountText = ""
    @State private var dueDate = Date.now

    @State private var category: BillCategory = .other

    @State private var isRecurring = false
    @State private var recurrence: BillRecurrence = .monthly
    @State private var notificationAdvance: HouseReminderAdvance = .none

    var body: some View {
        NavigationStack {
            Form {
                billSection
                dueDateSection
                categorySection
                recurrenceSection
                notificationSection
            }
            .navigationTitle("Add Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancellationToolbar
                confirmationToolbar
            }
        }
    }

    // MARK: - Bill

    private var billSection: some View {
        Section("Bill") {
            TextField(
                "Title",
                text: $title
            )
            .textInputAutocapitalization(.sentences)

            HStack {
                Text("£")
                    .foregroundStyle(.secondary)

                TextField(
                    "0.00",
                    text: $amountText
                )
                .keyboardType(.decimalPad)
            }
        }
    }

    // MARK: - Due Date

    private var dueDateSection: some View {
        Section("Due Date") {
            DatePicker(
                "Date",
                selection: $dueDate,
                in: startOfToday...,
                displayedComponents: .date
            )
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
                    BillCategory.allCases,
                    id: \.self
                ) { category in
                    Label(
                        categoryTitle(category),
                        systemImage: category.systemImage
                    )
                    .tag(category)
                }
            }
        }
    }

    // MARK: - Recurrence

    private var recurrenceSection: some View {
        Section("Recurrence") {
            Toggle(
                "Recurring Bill",
                isOn: $isRecurring
            )

            if isRecurring {
                Picker(
                    "Repeats",
                    selection: $recurrence
                ) {
                    ForEach(
                        BillRecurrence.allCases,
                        id: \.self
                    ) { recurrence in
                        Text(
                            recurrenceTitle(recurrence)
                        )
                        .tag(recurrence)
                    }
                }
            }
        }
    }

    private var notificationSection: some View {
        Section("Notification") {
            Picker("Notify", selection: $notificationAdvance) {
                ForEach(HouseReminderAdvance.allCases, id: \.self) { advance in
                    Text(advance.title).tag(advance)
                }
            }
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
                saveBill()
            }
            .disabled(!canSave)
        }
    }

    // MARK: - Validation

    private var canSave: Bool {
        !trimmedTitle.isEmpty
            && parsedAmount != nil
            && (parsedAmount ?? 0) > 0
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var parsedAmount: Double? {
        let normalizedValue = amountText
            .replacingOccurrences(
                of: ",",
                with: "."
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return Double(normalizedValue)
    }

    private var startOfToday: Date {
        Calendar.autoupdatingCurrent.startOfDay(
            for: .now
        )
    }

    // MARK: - Save

    private func saveBill() {
        guard
            canSave,
            let amount = parsedAmount
        else {
            return
        }

        onSave(
            trimmedTitle,
            amount,
            dueDate,
            category,
            isRecurring,
            isRecurring ? recurrence : nil,
            notificationAdvance
        )

        dismiss()
    }

    // MARK: - Titles

    private func categoryTitle(
        _ category: BillCategory
    ) -> String {
        switch category {
        case .electricity:
            return "Electricity"

        case .water:
            return "Water"

        case .internet:
            return "Internet"

        case .rent:
            return "Rent"

        case .gas:
            return "Gas"

        case .councilTax:
            return "Council Tax"

        case .subscription:
            return "Subscription"

        case .other:
            return "Other"
        }
    }

    private func recurrenceTitle(
        _ recurrence: BillRecurrence
    ) -> String {
        switch recurrence {
        case .weekly:
            return "Every week"

        case .monthly:
            return "Every month"

        case .yearly:
            return "Every year"
        }
    }
}

// MARK: - Preview

#Preview {
    AddBillView {
        title,
        amount,
        dueDate,
        category,
        isRecurring,
        recurrence,
        notificationAdvance in

        print(title)
        print(amount)
        print(dueDate)
        print(category)
        print(isRecurring)
        print(recurrence?.rawValue ?? "None")
        print(notificationAdvance.title)
    }
}
