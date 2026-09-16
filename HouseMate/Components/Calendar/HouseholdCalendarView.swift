import SwiftUI

struct HouseholdCalendarView: View {
    let tasks: [TaskModel]
    let bills: [BillModel]
    let reminders: [HouseReminderModel]
    var onOpenTasks: () -> Void = {}
    var onOpenBills: () -> Void = {}
    var onOpenReminders: () -> Void = {}
    var onRefresh: @MainActor () async -> Void = {}

    @Binding private var selectedDate: Date
    @State private var displayedMonth: Date
    @State private var isHeaderElevated = false

    private let calendar = Calendar.autoupdatingCurrent
    private let weekdaySymbols = Calendar.current.veryShortStandaloneWeekdaySymbols

    init(
        tasks: [TaskModel],
        bills: [BillModel],
        reminders: [HouseReminderModel],
        selectedDate: Binding<Date>,
        onOpenTasks: @escaping () -> Void = {},
        onOpenBills: @escaping () -> Void = {},
        onOpenReminders: @escaping () -> Void = {},
        onRefresh: @escaping @MainActor () async -> Void = {}
    ) {
        self.tasks = tasks
        self.bills = bills
        self.reminders = reminders
        self.onOpenTasks = onOpenTasks
        self.onOpenBills = onOpenBills
        self.onOpenReminders = onOpenReminders
        self.onRefresh = onRefresh
        _selectedDate = selectedDate
        _displayedMonth = State(initialValue: Calendar.current.startOfMonth(for: selectedDate.wrappedValue))
    }

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                    .background {
                        if isHeaderElevated {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .ignoresSafeArea(edges: .top)
                                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: isHeaderElevated)
                    .zIndex(1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        calendarCard
                        agenda
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 105)
                }
                .houseMatePullToRefresh(action: onRefresh)
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > 4
                } action: { _, isScrolled in
                    isHeaderElevated = isScrolled
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.90, blue: 1.00),
                Color(red: 0.94, green: 0.88, blue: 0.98),
                Color(red: 0.89, green: 0.96, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Calendar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Everything planned for your home")
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.52))
            }

            Spacer()

            Button("Today") {
                withAnimation(.smooth(duration: 0.35)) {
                    selectedDate = calendar.startOfDay(for: .now)
                    displayedMonth = calendar.startOfMonth(for: .now)
                }
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
        .padding(.top, 18)
    }

    private var calendarCard: some View {
        VStack(spacing: 16) {
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title3.weight(.semibold))

                Spacer()

                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.42))
                        .frame(maxWidth: .infinity)
                }

                ForEach(monthDays, id: \.self) { date in
                    dayCell(date)
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let today = calendar.isDateInToday(date)
        let currentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        let colors = eventColors(on: date)

        return Button {
            withAnimation(.smooth(duration: 0.25)) {
                selectedDate = date
                if !currentMonth {
                    displayedMonth = calendar.startOfMonth(for: date)
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 15, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? .white : Color.primary.opacity(currentMonth ? 0.9 : 0.28))
                    .frame(width: 34, height: 30)
                    .background {
                        if selected {
                            Circle().fill(Color.blue)
                        } else if today {
                            Circle().stroke(Color.blue, lineWidth: 1.5)
                        }
                    }

                HStack(spacing: 2) {
                    ForEach(Array(colors.prefix(3).enumerated()), id: \.offset) { _, color in
                        Circle().fill(color).frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
    }

    private var agenda: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(calendar.isDateInToday(selectedDate) ? "Today" : selectedDate.formatted(.dateTime.weekday(.wide)))
                        .font(.title2.bold())
                    Text(selectedDate.formatted(.dateTime.day().month(.wide).year()))
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.48))
                }
                Spacer()
                if !selectedEvents.isEmpty {
                    Text("\(selectedEvents.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.11), in: Capsule())
                }
            }

            if selectedEvents.isEmpty {
                ContentUnavailableView(
                    "Nothing planned",
                    systemImage: "calendar.badge.checkmark",
                    description: Text("Your home has no tasks, bills or reminders on this day.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(selectedEvents.enumerated()), id: \.element.id) { index, event in
                        Button { open(event.kind) } label: {
                            agendaRow(event)
                        }
                        .buttonStyle(.plain)

                        if index < selectedEvents.count - 1 {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        }
    }

    private func agendaRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: 13) {
            Image(systemName: event.kind.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(event.kind.color)
                .frame(width: 42, height: 42)
                .background(event.kind.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(event.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            if !event.timeText.isEmpty {
                Text(event.timeText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.primary.opacity(0.48))
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.25))
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var selectedEvents: [CalendarEvent] {
        events(on: selectedDate).sorted { $0.date < $1.date }
    }

    private func events(on date: Date) -> [CalendarEvent] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        var result: [CalendarEvent] = []

        result += tasks.compactMap { task in
            guard let dueDate = task.dueDate, calendar.isDate(dueDate, inSameDayAs: date) else { return nil }
            return CalendarEvent(
                id: "task-\(task.id)", title: task.title,
                subtitle: task.status == .completed ? "Completed task" : "Household task",
                date: dueDate, isAllDay: task.isAllDay, kind: .task
            )
        }

        result += bills.compactMap { bill in
            guard let dueDate = bill.dueDate, calendar.isDate(dueDate, inSameDayAs: date) else { return nil }
            return CalendarEvent(
                id: "bill-\(bill.id)", title: bill.title,
                subtitle: bill.status == .paid ? "Paid · £\(bill.amount.formatted(.number.precision(.fractionLength(2))))" : "Bill · £\(bill.amount.formatted(.number.precision(.fractionLength(2))))",
                date: dueDate, isAllDay: true, kind: .bill
            )
        }

        result += reminders.compactMap { reminder in
            let occurrence = reminder.recurrence == .never
                ? reminder.firstOccurrenceDate
                : reminder.nextOccurrence(after: dayStart)
            guard let occurrence,
                  occurrence >= dayStart,
                  occurrence < dayEnd else { return nil }
            return CalendarEvent(
                id: "reminder-\(reminder.id)-\(dayStart.timeIntervalSince1970)",
                title: reminder.title, subtitle: reminder.category.title,
                date: occurrence, isAllDay: false, kind: .reminder
            )
        }

        return result
    }

    private func eventColors(on date: Date) -> [Color] {
        var kinds: [CalendarEvent.Kind] = []
        for event in events(on: date) where !kinds.contains(event.kind) {
            kinds.append(event.kind)
        }
        return kinds.map(\.color)
    }

    private func open(_ kind: CalendarEvent.Kind) {
        switch kind {
        case .task: onOpenTasks()
        case .bill: onOpenBills()
        case .reminder: onOpenReminders()
        }
    }

    private func changeMonth(by value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        withAnimation(.smooth(duration: 0.3)) {
            displayedMonth = calendar.startOfMonth(for: month)
            selectedDate = displayedMonth
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    }

    private var orderedWeekdaySymbols: [String] {
        let start = max(0, calendar.firstWeekday - 1)
        return Array(weekdaySymbols[start...] + weekdaySymbols[..<start])
    }

    private var monthDays: [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        let weekday = calendar.component(.weekday, from: firstDay)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let total = leading + monthRange.count
        let cells = total <= 35 ? 35 : 42
        guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: firstDay) else { return [] }
        return (0..<cells).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }
}

private struct CalendarEvent: Identifiable {
    enum Kind: Hashable {
        case task, bill, reminder

        var systemImage: String {
            switch self {
            case .task: "checklist"
            case .bill: "creditcard.fill"
            case .reminder: "bell.fill"
            }
        }

        var color: Color {
            switch self {
            case .task: .blue
            case .bill: .orange
            case .reminder: .purple
            }
        }
    }

    let id: String
    let title: String
    let subtitle: String
    let date: Date
    let isAllDay: Bool
    let kind: Kind

    var timeText: String {
        isAllDay ? "All day" : date.formatted(date: .omitted, time: .shortened)
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }
}

#Preview {
    HouseholdCalendarView(
        tasks: TaskModel.mockList,
        bills: BillModel.mockList,
        reminders: HouseReminderModel.mockList,
        selectedDate: .constant(.now)
    )
}
