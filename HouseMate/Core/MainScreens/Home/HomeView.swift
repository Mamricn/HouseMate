//
//  HomeView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//


import SwiftUI

@Observable
@MainActor
final class HomeViewModel {

    var user: UserModel

    private let interactor: CoreInteractor
    let actionState = AsyncActionState()

    var tasks: [TaskModel] {
        interactor.tasks
    }

    var houseReminders: [HouseReminderModel] {
        interactor.houseReminders
    }

    var shoppingItems: [ShoppingItemModel] {
        interactor.shoppingItems
    }

    var bills: [BillModel] {
        interactor.bills
    }

    var members: [HouseholdMemberModel]

    private let calendar =
        Calendar.autoupdatingCurrent

    init(user: UserModel, members: [HouseholdMemberModel], interactor: CoreInteractor) {
        self.user = user
        self.members = members
        self.interactor = interactor
    }

    convenience init() {
        let container = DependencyContainer.make(environment: .mock)

        self.init(
            user: UserModel.mockList[0],
            members: HouseholdMemberModel.mockList,
            interactor: CoreInteractor(container: container)
        )
    }

    // MARK: - User

    var userName: String {
        let name = user.name?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard let name, !name.isEmpty else {
            return "there"
        }

        return name
    }

    var formattedToday: String {
        Date.now.formatted(
            .dateTime
                .weekday(.wide)
                .day(.twoDigits)
                .month(.twoDigits)
        )
    }

    // MARK: - Today's Tasks

    var todaysTasks: [TaskModel] {
        tasks
            .filter { task in
                guard let dueDate = task.dueDate else {
                    return false
                }

                return task.assignedToUserId == user.id
                    && calendar.isDateInToday(dueDate)
            }
            .sorted {
                ($0.dueDate ?? .distantFuture)
                    < ($1.dueDate ?? .distantFuture)
            }
    }

    // MARK: - Coming Up

    var comingUpItems: [ComingUpItem] {
        let now = Date.now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now

        let taskItems = tasks.compactMap { task -> ComingUpItem? in
            guard task.status == .pending,
                  task.assignedToUserId == user.id,
                  let dueDate = task.dueDate,
                  dueDate >= tomorrow else {
                return nil
            }

            return ComingUpItem(
                id: "task_\(task.id)",
                title: task.title,
                subtitle: "Your task",
                date: dueDate,
                systemImage: taskSystemImage(task.category),
                kind: .task
            )
        }

        let reminderItems = houseReminders.compactMap { reminder -> ComingUpItem? in
            guard let nextDate = reminder.nextOccurrence(after: now) else {
                return nil
            }

            return ComingUpItem(
                id: "reminder_\(reminder.id)",
                title: reminder.title,
                subtitle: reminder.category.title,
                date: nextDate,
                systemImage: reminder.category.systemImage,
                kind: .reminder
            )
        }

        return Array(
            (taskItems + reminderItems)
                .sorted { $0.date < $1.date }
                .prefix(4)
        )
    }

    private func taskSystemImage(_ category: TaskCategory) -> String {
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

    // MARK: - Recent Shopping Items

    var recentShoppingItems: [ShoppingItemModel] {
        let today = calendar.startOfDay(for: .now)

        guard
            let yesterday = calendar.date(
                byAdding: .day,
                value: -1,
                to: today
            ),
            let tomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: today
            )
        else {
            return []
        }

        return shoppingItems
            .filter { item in
                let relevantDate = item.isPurchased
                    ? item.purchasedAt ?? item.createdAt
                    : item.createdAt

                guard let relevantDate else {
                    return false
                }

                return relevantDate >= yesterday
                    && relevantDate < tomorrow
            }
            .sorted {
                let firstDate = $0.isPurchased
                    ? $0.purchasedAt ?? $0.createdAt
                    : $0.createdAt
                let secondDate = $1.isPurchased
                    ? $1.purchasedAt ?? $1.createdAt
                    : $1.createdAt

                return (firstDate ?? .distantPast) > (secondDate ?? .distantPast)
            }
    }

    // MARK: - Upcoming Bills

    var upcomingBills: [BillModel] {
        let today = calendar.startOfDay(for: .now)

        guard let endDate = calendar.date(
            byAdding: .day,
            value: 4,
            to: today
        ) else {
            return []
        }

        return bills
            .filter { bill in
                guard let dueDate = bill.dueDate else {
                    return false
                }

                return bill.status == .upcoming
                    && dueDate >= today
                    && dueDate < endDate
            }
            .sorted {
                ($0.dueDate ?? .distantFuture)
                    < ($1.dueDate ?? .distantFuture)
            }
    }

    // MARK: - Task Actions

    func toggleTaskStatus(_ task: TaskModel) async -> Bool {
        await actionState.perform {
            try await interactor.toggleTaskStatus(task)
        }
    }

    // MARK: - Shopping Actions

    func toggleShoppingItem(
        _ item: ShoppingItemModel
    ) async -> Bool {
        await actionState.perform {
            try await interactor.toggleShoppingItemPurchased(item)
        }
    }

    // MARK: - Bill Actions

    func markBillAsPaid(_ bill: BillModel) async -> Bool {
        await actionState.perform {
            try await interactor.markBillAsPaid(bill, paidByUserID: user.id)
        }
    }

    func refreshData() async {
        guard let householdID = user.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchTasks(householdID: householdID, currentUserID: user.id)
            try await interactor.fetchShoppingItems(householdID: householdID)
            try await interactor.fetchBills(householdID: householdID)
            try await interactor.fetchHouseReminders(householdID: householdID)
        }
    }

    func applyNotificationPreferences() async {
        await interactor.applyLocalNotificationPreferences()
    }

    func notificationAuthorizationStatus() async -> LocalNotificationAuthorizationStatus {
        await interactor.localNotificationAuthorizationStatus()
    }

    func sendTestNotification() async -> Bool {
        await actionState.perform {
            try await interactor.sendTestNotification()
        }
    }
}

struct HomeView: View {

    let viewModel: HomeViewModel
    let onSignOut: () -> Void

    @State private var showsSettings = false
    @State private var toast: AppToast?

    var body: some View {
        ZStack {
            backgroundGradient
            content
            toastOverlay
        }
        .sheet(
            isPresented: $showsSettings
        ) {
            SettingsView(
                user: viewModel.user,
                onSignOut: onSignOut,
                onNotificationPreferencesChanged: {
                    await viewModel.applyNotificationPreferences()
                },
                onSendTestNotification: {
                    await viewModel.sendTestNotification()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 20
            ) {
                header
                tasksCard
                comingUpCard
                shoppingCard
                billsCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 35)
        }
        .refreshable {
            await viewModel.refreshData()

            if let errorMessage = viewModel.actionState.errorMessage {
                showToast(
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello \(viewModel.userName)")
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                Text("It’s \(viewModel.formattedToday)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            profileButton
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }

    // MARK: - Profile Button

    private var profileButton: some View {
        Button {
            showsSettings = true
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)

                Image(systemName: "person.fill")
                    .font(
                        .system(
                            size: 21,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.blue)
            }
            .frame(width: 52, height: 52)
            .overlay {
                Circle()
                    .stroke(
                        .white.opacity(0.45),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: .blue.opacity(0.15),
                radius: 10,
                y: 5
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open settings")
    }

    // MARK: - Tasks Card

    private var tasksCard: some View {
        TaskCardView(
            tasks: viewModel.todaysTasks,
            members: viewModel.members,
            showsAddButton: false,
            onToggleStatus: { task in
                performAction(
                    successMessage: task.status == .completed
                        ? "Task marked as pending"
                        : "Task completed",
                    systemImage: task.status == .completed
                        ? "arrow.uturn.backward.circle"
                        : "checkmark.circle.fill",
                    color: task.status == .completed
                        ? .orange
                        : .green,
                    operation: {
                        await viewModel.toggleTaskStatus(task)
                    }
                )
            }
        )
        .dashboardShadow()
    }

    // MARK: - Coming Up Card

    private var comingUpCard: some View {
        ComingUpCardView(items: viewModel.comingUpItems)
        .dashboardShadow()
    }

    // MARK: - Shopping Card

    private var shoppingCard: some View {
        ShoppingCardView(
            items: viewModel.recentShoppingItems,
            showsAddButton: false,
            onTogglePurchased: { item in
                performAction(
                    successMessage: item.isPurchased
                        ? "\(item.name) added back"
                        : "\(item.name) purchased",
                    systemImage: item.isPurchased
                        ? "arrow.uturn.backward.circle"
                        : "cart.badge.checkmark",
                    color: item.isPurchased
                        ? .orange
                        : .green,
                    operation: {
                        await viewModel.toggleShoppingItem(item)
                    }
                )
            }
        )
        .dashboardShadow()
    }

    // MARK: - Bills Card

    private var billsCard: some View {
        BillsCardView(
            bills: viewModel.upcomingBills,
            title: "Upcoming Bills",
            showsAddButton: false,
            onMarkAsPaid: { bill in
                performAction(
                    successMessage: "\(bill.title) marked as paid",
                    systemImage: "checkmark.circle.fill",
                    color: .green,
                    operation: {
                        await viewModel.markBillAsPaid(bill)
                    }
                )
            }
        )
        .dashboardShadow()
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast {
            VStack {
                AppToastView(toast: toast)
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )

                Spacer()
            }
            .padding(.top, 12)
            .zIndex(100)
            .allowsHitTesting(false)
        }
    }

    private func showToast(message: String, systemImage: String, color: Color) {
        let newToast = AppToast(
            message: message,
            systemImage: systemImage,
            color: color
        )

        withAnimation(.spring(response: 0.4)) {
            toast = newToast
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard toast?.id == newToast.id else { return }

            withAnimation(.easeInOut(duration: 0.25)) {
                toast = nil
            }
        }
    }

    private func performAction(successMessage: String, systemImage: String, color: Color, operation: @escaping @MainActor () async -> Bool) {
        Task {
            let succeeded = await operation()

            showToast(
                message: succeeded
                    ? successMessage
                    : viewModel.actionState.errorMessage ?? "Something went wrong. Please try again.",
                systemImage: succeeded ? systemImage : "exclamationmark.triangle.fill",
                color: succeeded ? color : .red
            )
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(.systemBackground)

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.18),
                    Color.purple.opacity(0.10),
                    Color.cyan.opacity(0.08),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 150, y: -300)

            Circle()
                .fill(Color.purple.opacity(0.10))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: -160, y: 300)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Dashboard Shadow

private extension View {

    func dashboardShadow() -> some View {
        shadow(
            color: Color.black.opacity(0.07),
            radius: 14,
            x: 0,
            y: 7
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView(
        viewModel: HomeViewModel(),
        onSignOut: {}
    )
}
