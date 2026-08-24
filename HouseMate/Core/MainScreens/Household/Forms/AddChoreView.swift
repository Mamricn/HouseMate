//
//  AddChoreView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//



import SwiftUI

struct AddChoreView: View {

    @Environment(\.dismiss) private var dismiss

    let members: [HouseholdMemberModel]

    let onSave: (
        _ title: String,
        _ description: String?,
        _ assignedToUserId: String,
        _ dueDate: Date,
        _ isAllDay: Bool,
        _ category: TaskCategory
    ) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var assignedToUserId: String
    @State private var dueDate: Date
    @State private var isAllDay = false
    @State private var category: TaskCategory = .cleaning

    init(
        members: [HouseholdMemberModel],
        selectedDate: Date,
        onSave: @escaping (
            _ title: String,
            _ description: String?,
            _ assignedToUserId: String,
            _ dueDate: Date,
            _ isAllDay: Bool,
            _ category: TaskCategory
        ) -> Void
    ) {
        self.members = members
        self.onSave = onSave

        _assignedToUserId = State(
            initialValue: members.first?.userId ?? ""
        )

        _dueDate = State(
            initialValue: selectedDate
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                choreSection
                assignmentSection
                scheduleSection
                categorySection
            }
            .navigationTitle("Add Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancellationToolbar
                confirmationToolbar
            }
        }
    }

    // MARK: - Chore

    private var choreSection: some View {
        Section("Chore") {
            TextField(
                "Title",
                text: $title
            )
            .textInputAutocapitalization(.sentences)

            TextField(
                "Description (optional)",
                text: $description,
                axis: .vertical
            )
            .lineLimit(3...6)
            .textInputAutocapitalization(.sentences)
        }
    }

    // MARK: - Assignment

    private var assignmentSection: some View {
        Section("Assigned To") {
            if members.isEmpty {
                Text("No household members")
                    .foregroundStyle(.secondary)
            } else {
                Picker(
                    "Housemate",
                    selection: $assignedToUserId
                ) {
                    ForEach(members) { member in
                        Text(member.displayName)
                            .tag(member.userId)
                    }
                }
            }
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        Section("Schedule") {
            DatePicker(
                "Date",
                selection: $dueDate,
                displayedComponents: .date
            )

            Toggle(
                "All Day",
                isOn: $isAllDay
            )

            if !isAllDay {
                DatePicker(
                    "Time",
                    selection: $dueDate,
                    displayedComponents: .hourAndMinute
                )
            }
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
                    TaskCategory.allCases,
                    id: \.self
                ) { category in
                    Label(
                        categoryTitle(category),
                        systemImage: categorySystemImage(category)
                    )
                    .tag(category)
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
                saveChore()
            }
            .disabled(!canSave)
        }
    }

    // MARK: - Validation

    private var canSave: Bool {
        !trimmedTitle.isEmpty
            && !assignedToUserId.isEmpty
            && !members.isEmpty
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var trimmedDescription: String? {
        let value = description.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return value.isEmpty ? nil : value
    }

    // MARK: - Save

    private func saveChore() {
        guard canSave else {
            return
        }

        let finalDueDate = isAllDay
            ? Calendar.autoupdatingCurrent.startOfDay(
                for: dueDate
            )
            : dueDate

        onSave(
            trimmedTitle,
            trimmedDescription,
            assignedToUserId,
            finalDueDate,
            isAllDay,
            category
        )

        dismiss()
    }

    // MARK: - Category Helpers

    private func categoryTitle(
        _ category: TaskCategory
    ) -> String {
        switch category {
        case .cleaning:
            return "Cleaning"

        case .kitchen:
            return "Kitchen"

        case .bathroom:
            return "Bathroom"

        case .laundry:
            return "Laundry"

        case .trash:
            return "Trash"

        case .shopping:
            return "Shopping"

        case .other:
            return "Other"
        }
    }

    private func categorySystemImage(
        _ category: TaskCategory
    ) -> String {
        switch category {
        case .cleaning:
            return "sparkles"

        case .kitchen:
            return "fork.knife"

        case .bathroom:
            return "shower.fill"

        case .laundry:
            return "washer.fill"

        case .trash:
            return "trash.fill"

        case .shopping:
            return "cart.fill"

        case .other:
            return "checklist"
        }
    }
}

// MARK: - Preview

#Preview {
    AddChoreView(
        members: HouseholdMemberModel.mockList,
        selectedDate: .now
    ) {
        title,
        description,
        userId,
        dueDate,
        isAllDay,
        category in

        print(title)
        print(description ?? "")
        print(userId)
        print(dueDate)
        print(isAllDay)
        print(category)
    }
}
