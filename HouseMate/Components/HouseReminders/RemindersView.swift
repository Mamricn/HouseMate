//
//  RemindersView.swift
//  HouseMate
//

import SwiftUI

struct RemindersView: View {

    @Environment(\.dismissSearch) private var dismissSearch

    let reminders: [HouseReminderModel]
    let currentUserId: String
    let householdOwnerUserId: String?

    var onAdd: () -> Void = {}
    var onDelete: (HouseReminderModel) -> Void = { _ in }
    var onUpdate: (
        HouseReminderModel,
        String,
        String?,
        Date,
        HouseReminderRecurrence,
        HouseReminderCategory,
        HouseReminderAdvance
    ) -> Void = { _, _, _, _, _, _, _ in }

    @State private var referenceDate = Date.now
    @State private var selectedReminder: HouseReminderModel?
    @State private var editingReminder: HouseReminderModel?
    @State private var searchText = ""
    @State private var reminderContentBottom: CGFloat = 0
    @State private var scrollLayoutID = UUID()

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if sortedReminders.isEmpty {
                        emptyState
                    } else {
                        if !nearReminders.isEmpty {
                            reminderSection(title: "NEXT 7 DAYS", reminders: nearReminders)
                        }

                        if !laterReminders.isEmpty {
                            reminderSection(title: "LATER", reminders: laterReminders)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ReminderContentBottomKey.self,
                            value: proxy.frame(in: .named("remindersScroll")).maxY
                        )
                    }
                }
            }
            .id(scrollLayoutID)
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "remindersScroll")
            .onPreferenceChange(ReminderContentBottomKey.self) {
                reminderContentBottom = $0
            }
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        guard value.location.y > reminderContentBottom else { return }
                        searchText = ""
                        dismissSearch()
                    }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add reminder")
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search reminders"
        )
        .sheet(item: $selectedReminder) { reminder in
            reminderDetails(reminder)
                .presentationDetents([.height(560), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
        }
        .onAppear {
            referenceDate = .now
            resetSearch()

            Task { @MainActor in
                await Task.yield()
                dismissSearch()
                try? await Task.sleep(for: .milliseconds(120))
                scrollLayoutID = UUID()
            }
        }
        .onDisappear {
            resetSearch()
        }
    }

    private func resetSearch() {
        searchText = ""
        dismissSearch()
    }

    private func reminderSection(
        title: String,
        reminders: [HouseReminderModel]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary.opacity(0.52))
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                    HouseMateSwipeRow(
                        leadingAction: deleteAction(for: reminder),
                        trailingAction: nil
                    ) {
                        reminderRow(reminder)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticFeedback.selection()
                                selectedReminder = reminder
                            }
                            .padding(.vertical, 10)
                    }

                    if index < reminders.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .padding(.horizontal, 14)
            .reminderSurface()
        }
    }

    private func reminderRow(_ reminder: HouseReminderModel) -> some View {
        HStack(spacing: 12) {
            HouseMateSymbolView(
                systemName: reminder.category.systemImage,
                color: categoryColor(reminder.category),
                size: 42,
                symbolSize: 17
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text(nextDateText(for: reminder))

                    if reminder.recurrence != .never {
                        Text("•")
                        Text(reminder.recurrence.title)
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.55))
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary.opacity(0.28))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reminderDetails(_ reminder: HouseReminderModel) -> some View {
        ZStack {
            detailGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                detailHeader(for: reminder)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 14) {
                        HouseMateSymbolView(
                            systemName: reminder.category.systemImage,
                            color: categoryColor(reminder.category),
                                size: 54,
                                symbolSize: 22
                        )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.title)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .lineLimit(2)

                                Text(reminder.category.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.primary.opacity(0.55))
                            }
                    }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("NEXT REMINDER", systemImage: "calendar")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)

                            Text(fullNextDate(for: reminder))
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .reminderSurface()

                        HStack(spacing: 12) {
                            detailTile(
                                title: "Repeats",
                                value: reminder.recurrence.title,
                                systemImage: "repeat"
                            )

                            detailTile(
                                title: "Notify",
                                value: reminder.reminderAdvance.title,
                                systemImage: "bell.fill"
                            )
                        }

                        if let details = reminder.details,
                           !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("NOTES", systemImage: "note.text")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.primary.opacity(0.52))

                                Text(details)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .reminderSurface()
                        }

                        if canDelete(reminder) {
                            Button(role: .destructive) {
                                selectedReminder = nil
                                onDelete(reminder)
                            } label: {
                                Label("Delete Reminder", systemImage: "trash")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                            }
                            .buttonStyle(.plain)
                            .background(Color.red.opacity(0.09), in: Capsule())
                            .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(item: $editingReminder) { reminder in
            AddHouseReminderView(reminder: reminder) {
                title,
                details,
                firstOccurrenceDate,
                recurrence,
                category,
                reminderAdvance in

                onUpdate(
                    reminder,
                    title,
                    details,
                    firstOccurrenceDate,
                    recurrence,
                    category,
                    reminderAdvance
                )
                selectedReminder = nil
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func detailHeader(for reminder: HouseReminderModel) -> some View {
        HStack {
            Color.clear
                .frame(width: 64, height: 40)

            Spacer()

            Text("Reminder")
                .font(.headline)

            Spacer()

            if canDelete(reminder) {
                Button {
                    editingReminder = reminder
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 13)
                        .frame(height: 40)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.45), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            } else {
                Color.clear.frame(width: 64, height: 40)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private func detailTile(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.orange)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.52))

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(14)
        .reminderSurface()
    }

    private func deleteAction(for reminder: HouseReminderModel) -> HouseMateSwipeAction? {
        guard canDelete(reminder) else { return nil }

        return HouseMateSwipeAction(
            accessibilityLabel: "Delete \(reminder.title)",
            systemImage: "trash.fill",
            color: .red,
            action: { onDelete(reminder) }
        )
    }

    private func canDelete(_ reminder: HouseReminderModel) -> Bool {
        reminder.createdByUserId == currentUserId
            || currentUserId == householdOwnerUserId
    }

    private var sortedReminders: [HouseReminderModel] {
        filteredReminders.sorted {
            ($0.nextOccurrence(after: referenceDate) ?? .distantFuture)
                < ($1.nextOccurrence(after: referenceDate) ?? .distantFuture)
        }
    }

    private var filteredReminders: [HouseReminderModel] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return reminders }

        return reminders.filter { reminder in
            reminder.title.localizedCaseInsensitiveContains(query)
                || reminder.category.title.localizedCaseInsensitiveContains(query)
                || reminder.recurrence.title.localizedCaseInsensitiveContains(query)
                || (reminder.details?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var nearReminders: [HouseReminderModel] {
        guard let endDate = Calendar.autoupdatingCurrent.date(
            byAdding: .day,
            value: 7,
            to: referenceDate
        ) else { return [] }

        return sortedReminders.filter {
            guard let date = $0.nextOccurrence(after: referenceDate) else { return false }
            return date <= endDate
        }
    }

    private var laterReminders: [HouseReminderModel] {
        let nearIDs = Set(nearReminders.map(\.id))
        return sortedReminders.filter { !nearIDs.contains($0.id) }
    }

    private func nextDateText(for reminder: HouseReminderModel) -> String {
        guard let date = reminder.nextOccurrence(after: referenceDate) else { return "Expired" }
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private func fullNextDate(for reminder: HouseReminderModel) -> String {
        guard let date = reminder.nextOccurrence(after: referenceDate) else { return "Expired" }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide).year().hour().minute())
    }

    private func categoryColor(_ category: HouseReminderCategory) -> Color {
        switch category {
        case .generalWaste: .gray
        case .recycling: .green
        case .maintenance: .orange
        case .inspection: .blue
        case .meterReading: .purple
        case .delivery: .brown
        case .other: .pink
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "No house reminders"
                : "No results",
            systemImage: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "bell.slash"
                : "magnifyingglass",
            description: Text(
                searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Add collections, inspections or anything your household should remember."
                    : "No reminders match “\(searchText)”."
            )
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 54)
    }

    private var backgroundGradient: some View {
        detailGradient.ignoresSafeArea()
    }

    private var detailGradient: some View {
        ZStack {
            Color(.secondarySystemBackground)
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.16),
                    Color.pink.opacity(0.10),
                    Color.purple.opacity(0.06),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct ReminderContentBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension View {
    func reminderSurface() -> some View {
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
        RemindersView(
            reminders: HouseReminderModel.mockList,
            currentUserId: "user_1",
            householdOwnerUserId: "user_1"
        )
        .navigationTitle("Reminders")
    }
}
