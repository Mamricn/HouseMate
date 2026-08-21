//
//  ScheduleTaskRowView.swift
//  HouseMate
//
//  Created by Marcin Turek on 21/08/2026.
//

import SwiftUI

struct ScheduleTaskRowView: View {

    let task: TaskModel
    let member: HouseholdMemberModel?

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon

            taskInformation

            Spacer()

            statusIcon
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Category

    private var categoryIcon: some View {
        Image(systemName: categorySystemImage)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(categoryColor)
            .frame(width: 42, height: 42)
            .background {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(categoryColor.opacity(0.12))
            }
    }

    // MARK: - Information

    private var taskInformation: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .strikethrough(
                    task.status == .completed,
                    color: .secondary
                )
                .foregroundStyle(
                    task.status == .completed
                        ? .secondary
                        : .primary
                )

            HStack(spacing: 5) {
                if let member {
                    Text(member.displayName)
                } else {
                    Text("Unassigned")
                }

                Text("•")

                Text(formattedTime)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Status

    private var statusIcon: some View {
        Image(
            systemName: task.status == .completed
                ? "checkmark.circle.fill"
                : "circle"
        )
        .font(.system(size: 24))
        .foregroundStyle(
            task.status == .completed
                ? .green
                : .secondary
        )
    }

    // MARK: - Time

    private var formattedTime: String {
        guard !task.isAllDay else {
            return "All day"
        }

        guard let dueDate = task.dueDate else {
            return "No time"
        }

        return dueDate.formatted(
            date: .omitted,
            time: .shortened
        )
    }

    // MARK: - Category Appearance

    private var categorySystemImage: String {
        switch task.category {
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

    private var categoryColor: Color {
        switch task.category {
        case .cleaning:
            return .blue

        case .kitchen:
            return .orange

        case .bathroom:
            return .cyan

        case .laundry:
            return .purple

        case .trash:
            return .green

        case .shopping:
            return .pink

        case .other:
            return .gray
        }
    }
}

// MARK: - Previews

#Preview("Pending") {
    ScheduleTaskRowView(
        task: TaskModel.mock,
        member: HouseholdMemberModel.mockList[0]
    )
    .padding()
}

#Preview("Completed") {
    ScheduleTaskRowView(
        task: TaskModel.mockCompleted,
        member: HouseholdMemberModel.mockList[1]
    )
    .padding()
}
