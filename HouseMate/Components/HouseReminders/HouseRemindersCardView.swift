//
//  HouseRemindersCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

struct HouseRemindersCardView: View {

    let reminders: [HouseReminderModel]

    var currentUserId: String?
    var householdOwnerUserId: String?

    var showsAddButton: Bool = true

    var onAdd: () -> Void = {}
    var onDelete: ((HouseReminderModel) -> Void)? = nil

    @State private var referenceDate = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if reminders.isEmpty {
                emptyState
            } else {
                remindersList
            }
        }
        .padding()
        .background {
            cardBackground
        }
        .onAppear {
            referenceDate = .now
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("House Reminders")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showsAddButton {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Reminders List

    private var remindersList: some View {
        List {
            ForEach(sortedReminders) { reminder in
                reminderRow(reminder)
                    .listRowInsets(
                        EdgeInsets(
                            top: 3,
                            leading: 0,
                            bottom: 3,
                            trailing: 0
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // Delete po lewej stronie
                    .swipeActions(
                        edge: .leading,
                        allowsFullSwipe: false
                    ) {
                        if canDelete(reminder),
                           onDelete != nil {
                            deleteButton(for: reminder)
                        }
                    }
                    .roundedSwipeActions()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 220)
    }

    // MARK: - Reminder Row

    private func reminderRow(
        _ reminder: HouseReminderModel
    ) -> some View {
        HStack(spacing: 12) {
            reminderIcon(for: reminder)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let details = reminder.details,
                   !details.isEmpty {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 5) {
                    Text(nextDateText(for: reminder))

                    if reminder.recurrence != .never {
                        Text("•")

                        Text(reminder.recurrence.title)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: - Icon

    private func reminderIcon(
        for reminder: HouseReminderModel
    ) -> some View {
        Image(
            systemName: reminder.category.systemImage
        )
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(
            categoryColor(reminder.category)
        )
        .frame(width: 42, height: 42)
        .background {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(
                categoryColor(reminder.category)
                    .opacity(0.12)
            )
        }
    }

    // MARK: - Delete Action

    private func deleteButton(
        for reminder: HouseReminderModel
    ) -> some View {
        Button(role: .destructive) {
            onDelete?(reminder)
        } label: {
            Label(
                "Delete",
                systemImage: "trash.fill"
            )
        }
    }

    private func canDelete(_ reminder: HouseReminderModel) -> Bool {
        reminder.createdByUserId == currentUserId
            || currentUserId == householdOwnerUserId
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.slash")
                .font(.system(size: 28))
                .foregroundStyle(.blue)

            Text("No house reminders")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(
                "Add collections, inspections " +
                "or other recurring information."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }

    // MARK: - Calculated Values

    private var sortedReminders: [HouseReminderModel] {
        reminders.sorted { first, second in
            let firstDate = first.nextOccurrence(
                after: referenceDate
            )

            let secondDate = second.nextOccurrence(
                after: referenceDate
            )

            return (firstDate ?? .distantFuture)
                < (secondDate ?? .distantFuture)
        }
    }

    private func nextDateText(
        for reminder: HouseReminderModel
    ) -> String {
        guard let nextDate = reminder.nextOccurrence(
            after: referenceDate
        ) else {
            return "Expired"
        }

        let calendar = Calendar.autoupdatingCurrent

        if calendar.isDateInToday(nextDate) {
            return "Today"
        }

        if calendar.isDateInTomorrow(nextDate) {
            return "Tomorrow"
        }

        return nextDate.formatted(
            .dateTime
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
        )
    }

    private func categoryColor(
        _ category: HouseReminderCategory
    ) -> Color {
        switch category {
        case .generalWaste:
            return .gray

        case .recycling:
            return .green

        case .maintenance:
            return .orange

        case .inspection:
            return .blue

        case .meterReading:
            return .purple

        case .delivery:
            return .brown

        case .other:
            return .secondary
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 24,
            style: .continuous
        )
        .fill(.ultraThickMaterial)
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                .white.opacity(0.35),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Previews

#Preview("Reminders") {
    HouseRemindersCardView(
        reminders: HouseReminderModel.mockList,
        onAdd: {
            print("Add reminder")
        },
        onDelete: { reminder in
            print("Delete \(reminder.title)")
        }
    )
    .padding()
}

#Preview("Empty") {
    HouseRemindersCardView(
        reminders: []
    )
    .padding()
}
