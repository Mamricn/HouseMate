//
//  CleaningScheduleView.swift
//  HouseMate
//

import SwiftUI

struct CleaningScheduleView: View {

    @Binding var selectedDate: Date

    let tasks: [TaskModel]
    let members: [HouseholdMemberModel]
    var onAdd: () -> Void = {}
    var onToggleStatus: (TaskModel) -> Void = { _ in }
    var onDelete: (TaskModel) -> Void = { _ in }

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    weekCard
                    progressCard
                    tasksSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add chore")
            }
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    moveWeek(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Button("Today") {
                    withAnimation(.snappy) {
                        selectedDate = .now
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)

                Spacer()

                Button {
                    moveWeek(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)

            HStack(spacing: 6) {
                ForEach(weekDates, id: \.self) { date in
                    dayButton(date)
                }
            }

            Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding(16)
        .cleaningSurface()
    }

    private func dayButton(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasTasks = tasks.contains { task in
            task.dueDate.map { calendar.isDate($0, inSameDayAs: date) } == true
        }

        return Button {
            withAnimation(.snappy(duration: 0.25)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 5) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2)
                    .fontWeight(.semibold)

                Text(date.formatted(.dateTime.day()))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Circle()
                    .fill(isSelected ? .white : hasTasks ? .blue : .clear)
                    .frame(width: 4, height: 4)
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(
                isSelected ? Color.blue : Color.clear,
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var progressCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(.blue.opacity(0.13), lineWidth: 7)

                Circle()
                    .trim(from: 0, to: completionProgress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(completedTasks.count)/\(selectedDateTasks.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(progressTitle)
                    .font(.headline)

                Text(progressSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .cleaningSurface()
        .animation(.snappy, value: completedTasks.count)
    }

    @ViewBuilder
    private var tasksSection: some View {
        if selectedDateTasks.isEmpty {
            ContentUnavailableView(
                "No cleaning planned",
                systemImage: "calendar.badge.checkmark",
                description: Text("There are no chores assigned for this day.")
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 50)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("CHORES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(Array(selectedDateTasks.enumerated()), id: \.element.id) { index, task in
                        let member = members.first { $0.userId == task.assignedToUserId }

                        HouseMateSwipeRow(
                            leadingAction: HouseMateSwipeAction(
                                accessibilityLabel: "Delete \(task.title)",
                                systemImage: "trash.fill",
                                color: .red,
                                action: { onDelete(task) }
                            ),
                            trailingAction: nil
                        ) {
                            cleaningTaskRow(task, member: member)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticFeedback.selection()
                                    onToggleStatus(task)
                                }
                                .padding(.vertical, 9)
                        }
                        .frame(maxWidth: .infinity)

                        if index < selectedDateTasks.count - 1 {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .cleaningSurface()
            }
        }
    }

    private var selectedDateTasks: [TaskModel] {
        tasks
            .filter { task in
                task.dueDate.map { calendar.isDate($0, inSameDayAs: selectedDate) } == true
            }
            .sorted {
                if $0.isAllDay != $1.isAllDay { return $0.isAllDay }
                return ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
    }

    private func cleaningTaskRow(
        _ task: TaskModel,
        member: HouseholdMemberModel?
    ) -> some View {
        HStack(spacing: 12) {
            HouseMateSymbolView(
                systemName: categorySystemImage(task.category),
                color: categoryColor(task.category),
                size: 42,
                symbolSize: 17
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        task.status == .completed
                            ? Color.primary.opacity(0.52)
                            : Color.primary
                    )
                    .strikethrough(
                        task.status == .completed,
                        color: Color.primary.opacity(0.52)
                    )
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let member {
                        CachedProfileImage(
                            urlString: member.profileImageUrl,
                            displayName: member.displayName,
                            size: 18
                        )

                        Text(member.displayName)
                            .lineLimit(1)
                    } else {
                        Text("Unassigned")
                    }

                    Text("•")
                    Text(taskTime(task))
                        .fixedSize(horizontal: true, vertical: false)
                }
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.55))
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(
                    task.status == .completed
                        ? Color.blue
                        : Color.primary.opacity(0.48)
                )
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .animation(.snappy(duration: 0.22), value: task.status)
    }

    private func taskTime(_ task: TaskModel) -> String {
        if task.isAllDay { return "All day" }
        guard let dueDate = task.dueDate else { return "No time" }
        return dueDate.formatted(date: .omitted, time: .shortened)
    }

    private func categorySystemImage(_ category: TaskCategory) -> String {
        switch category {
        case .cleaning: "sparkles"
        case .kitchen: "fork.knife"
        case .bathroom: "shower.fill"
        case .laundry: "washer.fill"
        case .trash: "trash.fill"
        case .shopping: "cart.fill"
        case .other: "checklist"
        }
    }

    private func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .cleaning: .blue
        case .kitchen: .orange
        case .bathroom: .cyan
        case .laundry: .purple
        case .trash: .green
        case .shopping: .pink
        case .other: .gray
        }
    }

    private var completedTasks: [TaskModel] {
        selectedDateTasks.filter { $0.status == .completed }
    }

    private var completionProgress: Double {
        guard !selectedDateTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(selectedDateTasks.count)
    }

    private var progressTitle: String {
        guard !selectedDateTasks.isEmpty else { return "A clear day" }
        return completionProgress == 1 ? "All done" : "Today's progress"
    }

    private var progressSubtitle: String {
        guard !selectedDateTasks.isEmpty else { return "Nothing scheduled for this day" }
        let remaining = selectedDateTasks.count - completedTasks.count
        return remaining == 1 ? "1 chore remaining" : "\(remaining) chores remaining"
    }

    private var weekDates: [Date] {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let weekday = calendar.component(.weekday, from: selectedDay)
        let daysSinceMonday = (weekday + 5) % 7

        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: selectedDay) else {
            return []
        }

        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private func moveWeek(by value: Int) {
        guard let date = calendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) else {
            return
        }

        withAnimation(.snappy) {
            selectedDate = date
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color(.secondarySystemBackground)
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.16),
                    Color.blue.opacity(0.12),
                    Color.purple.opacity(0.08),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func cleaningSurface() -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

#Preview {
    NavigationStack {
        CleaningScheduleView(
            selectedDate: .constant(.now),
            tasks: TaskModel.mockList,
            members: HouseholdMemberModel.mockList
        )
        .navigationTitle("Cleaning Schedule")
    }
}
