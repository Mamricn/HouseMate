//
//  ScheduleCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 21/08/2026.
//



import SwiftUI

struct ScheduleCardView: View {

    @Binding var selectedDate: Date

    let tasks: [TaskModel]
    let members: [HouseholdMemberModel]

    var showsAddButton: Bool = true

    var onAdd: () -> Void = {}
    var onToggleStatus: (TaskModel) -> Void = { _ in }
    var onDelete: (TaskModel) -> Void = { _ in }

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            weekPicker
            selectedDateHeader

            if selectedDateTasks.isEmpty {
                emptyState
            } else {
                tasksList
            }
        }
        .padding()
        .background {
            cardBackground
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Cleaning Schedule")
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

    // MARK: - Week Picker

    private var weekPicker: some View {
        HStack(spacing: 6) {
            ForEach(weekDates, id: \.self) { date in
                dayButton(for: date)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func dayButton(for date: Date) -> some View {
        let isSelected = calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 6) {
                Text(
                    date.formatted(
                        .dateTime.weekday(.narrow)
                    )
                )
                .font(.caption2)
                .fontWeight(.semibold)

                Text(
                    date.formatted(
                        .dateTime.day()
                    )
                )
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            .foregroundStyle(
                isSelected
                    ? Color.white
                    : Color.secondary
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(
                    isSelected
                        ? Color.blue
                        : Color.clear
                )
            }
            .shadow(
                color: isSelected
                    ? Color.blue.opacity(0.25)
                    : Color.clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected Date

    private var selectedDateHeader: some View {
        Text(
            selectedDate.formatted(
                .dateTime
                    .weekday(.wide)
                    .day()
                    .month(.wide)
            )
        )
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
    }

    // MARK: - Tasks List

    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(selectedDateTasks) { task in
                let member = members.first {
                    $0.userId == task.assignedToUserId
                }

                    HouseMateSwipeRow(
                        leadingAction: deleteAction(for: task),
                        trailingAction: nil
                    ) {
                        ScheduleTaskRowView(task: task, member: member)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticFeedback.selection()
                                onToggleStatus(task)
                            }
                            .padding(.vertical, 2)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 220)
    }

    // MARK: - Delete Action

    private func deleteAction(for task: TaskModel) -> HouseMateSwipeAction {
        HouseMateSwipeAction(
            accessibilityLabel: "Delete task",
            systemImage: "trash.fill",
            color: .red
        ) {
            onDelete(task)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 28))
                .foregroundStyle(.blue)

            Text("No cleaning planned")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("There are no chores assigned for this day.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
    }

    // MARK: - Background

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 24,
            style: .continuous
        )
        .fill(.ultraThinMaterial)
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

    // MARK: - Filtered Tasks

    private var selectedDateTasks: [TaskModel] {
        tasks
            .filter { task in
                guard let dueDate = task.dueDate else {
                    return false
                }

                return calendar.isDate(
                    dueDate,
                    inSameDayAs: selectedDate
                )
            }
            .sorted { firstTask, secondTask in
                if firstTask.isAllDay != secondTask.isAllDay {
                    return firstTask.isAllDay
                }

                return (firstTask.dueDate ?? .distantFuture)
                    < (secondTask.dueDate ?? .distantFuture)
            }
    }

    // MARK: - Week Dates

    private var weekDates: [Date] {
        let selectedDay = calendar.startOfDay(
            for: selectedDate
        )

        let weekday = calendar.component(
            .weekday,
            from: selectedDay
        )

        let daysSinceMonday = (weekday + 5) % 7

        guard let monday = calendar.date(
            byAdding: .day,
            value: -daysSinceMonday,
            to: selectedDay
        ) else {
            return []
        }

        return (0..<7).compactMap { dayOffset in
            calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: monday
            )
        }
    }
}

// MARK: - Previews

#Preview("With Tasks") {
    ScheduleCardView(
        selectedDate: .constant(.now),
        tasks: TaskModel.mockList,
        members: HouseholdMemberModel.mockList,
        onAdd: {
            print("Add chore")
        },
        onToggleStatus: { task in
            print("Toggle: \(task.title)")
        },
        onDelete: { task in
            print("Delete: \(task.title)")
        }
    )
    .padding()
}

#Preview("Empty") {
    ScheduleCardView(
        selectedDate: .constant(.now),
        tasks: [],
        members: HouseholdMemberModel.mockList
    )
    .padding()
}
