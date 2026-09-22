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

    var shoppingLists: [ShoppingCollection] {
        interactor.shoppingLists
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

    var firstName: String {
        let name = user.name?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard let name, !name.isEmpty else {
            return "there"
        }

        return name.split(whereSeparator: \Character.isWhitespace)
            .first
            .map(String.init)
            ?? name
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

                return task.status == .pending
                    && task.assignedToUserId == user.id
                    && calendar.isDateInToday(dueDate)
            }
            .sorted {
                ($0.dueDate ?? .distantFuture)
                    < ($1.dueDate ?? .distantFuture)
            }
    }

    func ensureTodaysTasksLoaded() async {
        var previousTaskCount = -1

        while interactor.canLoadMoreTasks,
              tasks.count != previousTaskCount {
            previousTaskCount = tasks.count

            do {
                try await interactor.loadMoreTasks()
            } catch {
                return
            }
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
        interactor.trackEvent(Event.toggleTaskStatusStart(task: task))
        do {
            try await actionState.run { try await self.interactor.toggleTaskStatus(task) }
            interactor.trackEvent(Event.toggleTaskStatusSuccess(task: task))
            return true
        } catch {
            interactor.trackEvent(Event.toggleTaskStatusFail(error: error, task: task))
            return false
        }
    }

    // MARK: - Shopping Actions

    func toggleShoppingItem(
        _ item: ShoppingItemModel
    ) async -> Bool {
        interactor.trackEvent(Event.toggleShoppingItemStart(item: item))
        do {
            try await actionState.run { try await self.interactor.toggleShoppingItemPurchased(item) }
            interactor.trackEvent(Event.toggleShoppingItemSuccess(item: item))
            return true
        } catch {
            interactor.trackEvent(Event.toggleShoppingItemFail(error: error, item: item))
            return false
        }
    }

    // MARK: - Bill Actions

    func markBillAsPaid(_ bill: BillModel) async -> Bool {
        interactor.trackEvent(Event.markBillAsPaidStart(bill: bill))
        do {
            try await actionState.run { try await self.interactor.markBillAsPaid(bill, paidByUserID: self.user.id) }
            interactor.trackEvent(Event.markBillAsPaidSuccess(bill: bill))
            return true
        } catch {
            interactor.trackEvent(Event.markBillAsPaidFail(error: error, bill: bill))
            return false
        }
    }

    func refreshData() async {
        guard let householdID = user.householdId else {
            return
        }

        interactor.trackEvent(Event.refreshDataStart)
        do {
            try await actionState.run {
            let tasksStartedAt = StartupDiagnostics.begin("Home tasks setup")
            try await self.interactor.fetchTasks(householdID: householdID, currentUserID: self.user.id)
            StartupDiagnostics.end("Home tasks setup", startedAt: tasksStartedAt)

            let shoppingStartedAt = StartupDiagnostics.begin("Home shopping setup")
            try await self.interactor.fetchShoppingItems(householdID: householdID)
            StartupDiagnostics.end("Home shopping setup", startedAt: shoppingStartedAt)

            let billsStartedAt = StartupDiagnostics.begin("Home bills setup")
            try await self.interactor.fetchBills(householdID: householdID)
            StartupDiagnostics.end("Home bills setup", startedAt: billsStartedAt)

            let remindersStartedAt = StartupDiagnostics.begin("Home reminders setup")
            try await self.interactor.fetchHouseReminders(householdID: householdID)
            StartupDiagnostics.end("Home reminders setup", startedAt: remindersStartedAt)
            }
            interactor.trackEvent(Event.refreshDataSuccess)
        } catch {
            interactor.trackEvent(Event.refreshDataFail(error: error))
        }
    }

    func applyNotificationPreferences() async {
        interactor.trackEvent(Event.applyNotificationPreferencesStart)
        await interactor.applyLocalNotificationPreferences()
        interactor.trackEvent(Event.applyNotificationPreferencesSuccess)
    }

    func notificationAuthorizationStatus() async -> LocalNotificationAuthorizationStatus {
        interactor.trackEvent(Event.notificationAuthorizationStatusStart)
        let status = await interactor.localNotificationAuthorizationStatus()
        interactor.trackEvent(Event.notificationAuthorizationStatusSuccess(status: status))
        return status
    }

    func sendTestNotification() async -> Bool {
        interactor.trackEvent(Event.sendTestNotificationStart)
        do {
            try await actionState.run { try await self.interactor.sendTestNotification() }
            interactor.trackEvent(Event.sendTestNotificationSuccess)
            return true
        } catch {
            interactor.trackEvent(Event.sendTestNotificationFail(error: error))
            return false
        }
    }

    func registerRemoteNotifications() async -> Bool {
        interactor.trackEvent(Event.registerRemoteNotificationsStart)
        do {
            try await actionState.run { try await self.interactor.registerRemoteNotifications(for: self.user) }
            interactor.trackEvent(Event.registerRemoteNotificationsSuccess)
            return true
        } catch {
            interactor.trackEvent(Event.registerRemoteNotificationsFail(error: error))
            return false
        }
    }

    func updateAutomaticWeeklyAssignment(_ isEnabled: Bool) async -> Bool {
        interactor.trackEvent(Event.updateAutomaticWeeklyAssignmentStart(isEnabled: isEnabled))
        do {
            try await actionState.run {
                try await self.interactor.updateAutomaticWeeklyAssignment(isEnabled: isEnabled, requestedByUserID: self.user.id)
            }
            interactor.trackEvent(Event.updateAutomaticWeeklyAssignmentSuccess(isEnabled: isEnabled))
            return true
        } catch {
            interactor.trackEvent(Event.updateAutomaticWeeklyAssignmentFail(error: error, isEnabled: isEnabled))
            return false
        }
    }

    func runWeeklyAssignmentNow() async -> Bool {
        interactor.trackEvent(Event.runWeeklyAssignmentNowStart)
        do {
            try await actionState.run { try await self.interactor.runWeeklyAssignmentNow(requestedByUserID: self.user.id) }
            interactor.trackEvent(Event.runWeeklyAssignmentNowSuccess)
            return true
        } catch {
            interactor.trackEvent(Event.runWeeklyAssignmentNowFail(error: error))
            return false
        }
    }

    enum Event: LoggableEvent {
        case toggleTaskStatusStart(task: TaskModel), toggleTaskStatusSuccess(task: TaskModel), toggleTaskStatusFail(error: Error, task: TaskModel)
        case toggleShoppingItemStart(item: ShoppingItemModel), toggleShoppingItemSuccess(item: ShoppingItemModel), toggleShoppingItemFail(error: Error, item: ShoppingItemModel)
        case markBillAsPaidStart(bill: BillModel), markBillAsPaidSuccess(bill: BillModel), markBillAsPaidFail(error: Error, bill: BillModel)
        case refreshDataStart, refreshDataSuccess, refreshDataFail(error: Error)
        case applyNotificationPreferencesStart, applyNotificationPreferencesSuccess
        case notificationAuthorizationStatusStart, notificationAuthorizationStatusSuccess(status: LocalNotificationAuthorizationStatus)
        case sendTestNotificationStart, sendTestNotificationSuccess, sendTestNotificationFail(error: Error)
        case registerRemoteNotificationsStart, registerRemoteNotificationsSuccess, registerRemoteNotificationsFail(error: Error)
        case updateAutomaticWeeklyAssignmentStart(isEnabled: Bool), updateAutomaticWeeklyAssignmentSuccess(isEnabled: Bool), updateAutomaticWeeklyAssignmentFail(error: Error, isEnabled: Bool)
        case runWeeklyAssignmentNowStart, runWeeklyAssignmentNowSuccess, runWeeklyAssignmentNowFail(error: Error)

        var eventName: String {
            switch self {
            case .toggleTaskStatusStart: "HomeView_ToggleTaskStatus_Start";
            case .toggleTaskStatusSuccess: "HomeView_ToggleTaskStatus_Success";
            case .toggleTaskStatusFail: "HomeView_ToggleTaskStatus_Fail"
            case .toggleShoppingItemStart: "HomeView_ToggleShoppingItem_Start";
            case .toggleShoppingItemSuccess: "HomeView_ToggleShoppingItem_Success";
            case .toggleShoppingItemFail: "HomeView_ToggleShoppingItem_Fail"
            case .markBillAsPaidStart: "HomeView_MarkBillAsPaid_Start";
            case .markBillAsPaidSuccess: "HomeView_MarkBillAsPaid_Success";
            case .markBillAsPaidFail: "HomeView_MarkBillAsPaid_Fail"
            case .refreshDataStart: "HomeView_RefreshData_Start";
            case .refreshDataSuccess: "HomeView_RefreshData_Success";
            case .refreshDataFail: "HomeView_RefreshData_Fail"
            case .applyNotificationPreferencesStart: "HomeView_ApplyNotificationPreferences_Start";
            case .applyNotificationPreferencesSuccess: "HomeView_ApplyNotificationPreferences_Success"
            case .notificationAuthorizationStatusStart: "HomeView_NotificationAuthorizationStatus_Start";
            case .notificationAuthorizationStatusSuccess: "HomeView_NotificationAuthorizationStatus_Success"
            case .sendTestNotificationStart: "HomeView_SendTestNotification_Start";
            case .sendTestNotificationSuccess: "HomeView_SendTestNotification_Success";
            case .sendTestNotificationFail: "HomeView_SendTestNotification_Fail"
            case .registerRemoteNotificationsStart: "HomeView_RegisterRemoteNotifications_Start";
            case .registerRemoteNotificationsSuccess: "HomeView_RegisterRemoteNotifications_Success";
            case .registerRemoteNotificationsFail: "HomeView_RegisterRemoteNotifications_Fail"
            case .updateAutomaticWeeklyAssignmentStart: "HomeView_UpdateAutomaticWeeklyAssignment_Start";
            case .updateAutomaticWeeklyAssignmentSuccess: "HomeView_UpdateAutomaticWeeklyAssignment_Success";
            case .updateAutomaticWeeklyAssignmentFail: "HomeView_UpdateAutomaticWeeklyAssignment_Fail"
            case .runWeeklyAssignmentNowStart: "HomeView_RunWeeklyAssignmentNow_Start";
            case .runWeeklyAssignmentNowSuccess: "HomeView_RunWeeklyAssignmentNow_Success";
            case .runWeeklyAssignmentNowFail: "HomeView_RunWeeklyAssignmentNow_Fail"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .toggleTaskStatusStart(let model), .toggleTaskStatusSuccess(let model): model.eventParameters
            case .toggleTaskStatusFail(let error, let model): model.eventParameters.merging(error.eventParameters) { current, _ in current }
            case .toggleShoppingItemStart(let model), .toggleShoppingItemSuccess(let model): model.eventParameters
            case .toggleShoppingItemFail(let error, let model): model.eventParameters.merging(error.eventParameters) { current, _ in current }
            case .markBillAsPaidStart(let model), .markBillAsPaidSuccess(let model): model.eventParameters
            case .markBillAsPaidFail(let error, let model): model.eventParameters.merging(error.eventParameters) { current, _ in current }
            case .notificationAuthorizationStatusSuccess(let status): ["authorization_status": String(describing: status)]
            case .updateAutomaticWeeklyAssignmentStart(let value), .updateAutomaticWeeklyAssignmentSuccess(let value): ["is_enabled": value]
            case .updateAutomaticWeeklyAssignmentFail(let error, let value): ["is_enabled": value].merging(error.eventParameters) { current, _ in current }
            case .refreshDataFail(let error), .sendTestNotificationFail(let error), .registerRemoteNotificationsFail(let error), .runWeeklyAssignmentNowFail(let error): error.eventParameters
            default: nil
            }
        }

        var type: LogType {
            switch self {
            case .toggleTaskStatusFail, .toggleShoppingItemFail, .markBillAsPaidFail, .refreshDataFail, .sendTestNotificationFail, .registerRemoteNotificationsFail, .updateAutomaticWeeklyAssignmentFail, .runWeeklyAssignmentNowFail: .severe
            default: .analytic
            }
        }
    }
}

struct HomeView: View {

    let viewModel: HomeViewModel
    let onSignOut: () -> Void
    var onOpenSettings: () -> Void = {}
    var onOpenShopping: (String) -> Void = { _ in }
    var onOpenReminders: () -> Void = {}
    var onOpenBills: () -> Void = {}
    var onOpenTasks: () -> Void = {}

    @State private var toast: AppToast?
    @State private var isHeaderElevated = false
    @State private var pullDistance: CGFloat = 0
    @State private var isRefreshing = false
    @State private var isRefreshArmed = false
    @State private var didTriggerRefresh = false

    private let refreshThreshold: CGFloat = 72

    var body: some View {
        ZStack {
            backgroundGradient
            content
            toastOverlay
        }
        .task(id: viewModel.tasks.count) {
            await viewModel.ensureTodaysTasksLoaded()
        }
        .screenAppearAnalytics(name: "HomeView")
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 18)
                .background {
                    if isHeaderElevated {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea(edges: .top)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isHeaderElevated)

            ScrollView {
                LazyVStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    tasksCard
                    compactOverviewCards
                    shoppingCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 35)
            }
            .scrollIndicators(.hidden)
            .overlay(alignment: .top) {
                customRefreshIndicator
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(0, -geometry.contentOffset.y)
            } action: { oldPullDistance, newPullDistance in
                pullDistance = newPullDistance

                if newPullDistance < 4, !isRefreshing {
                    didTriggerRefresh = false
                    isRefreshArmed = false
                }

                if newPullDistance >= refreshThreshold,
                   !isRefreshArmed,
                   !didTriggerRefresh,
                   !isRefreshing {
                    isRefreshArmed = true
                    HapticFeedback.selection()
                }

                if oldPullDistance >= refreshThreshold,
                   newPullDistance < refreshThreshold,
                   isRefreshArmed,
                   !didTriggerRefresh,
                   !isRefreshing {
                    isRefreshArmed = false
                    didTriggerRefresh = true
                    refreshHome()
                }
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y > 4
            } action: { _, isScrolled in
                isHeaderElevated = isScrolled
            }
        }
    }

    private var customRefreshIndicator: some View {
        let progress = min(pullDistance / refreshThreshold, 1)

        return Group {
            refreshHouseIcon(progress: progress)
        }
        .padding(9)
        .background(.ultraThinMaterial, in: Circle())
        .opacity(pullDistance > 8 || isRefreshing ? 1 : 0)
        .offset(y: 8)
        .animation(.easeOut(duration: 0.18), value: pullDistance)
        .animation(.easeInOut(duration: 0.2), value: isRefreshing)
        .allowsHitTesting(false)
    }

    private func refreshHouseIcon(progress: CGFloat) -> some View {
        ZStack {
            Image(systemName: "house.fill")
                .foregroundStyle(.secondary.opacity(0.55))

            Image(systemName: "house.fill")
                .foregroundStyle(.blue)
                .mask(alignment: .bottom) {
                    Rectangle()
                        .scaleEffect(
                            y: isRefreshing ? 1 : progress,
                            anchor: .bottom
                        )
                }
                .symbolEffect(.bounce, value: isRefreshArmed)
                .symbolEffect(
                    .pulse,
                    options: .repeating,
                    isActive: isRefreshing
                )
        }
        .font(.system(size: 18, weight: .semibold))
        .frame(width: 22, height: 22)
        .scaleEffect(isRefreshing ? 1 : 0.78 + progress * 0.22)
        .animation(.snappy(duration: 0.24), value: isRefreshArmed)
    }

    private func refreshHome() {
        isRefreshing = true

        Task {
            await viewModel.refreshData()

            if let errorMessage = viewModel.actionState.errorMessage {
                showToast(
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle.fill",
                    color: .red
                )
            }

            isRefreshing = false
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            profileButton

            VStack(alignment: .leading, spacing: 2) {
                Text("Hey, \(viewModel.firstName)")
                    .font(
                        .system(
                            size: 19,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(viewModel.formattedToday)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .zIndex(1)
    }

    // MARK: - Profile Button

    private var profileButton: some View {
        Button {
            onOpenSettings()
        } label: {
            CachedProfileImage(
                urlString: viewModel.user.profileImageUrl,
                displayName: viewModel.user.name ?? "Housemate",
                size: 52
            )
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
            showsAddButton: false,
            usesThinMaterial: true,
            onOpenAll: {
                onOpenTasks()
            },
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

    // MARK: - Compact Overview Cards

    private var compactOverviewCards: some View {
        HStack(alignment: .top, spacing: 12) {
            HomeCompactComingUpCard(
                items: viewModel.comingUpItems,
                onTap: {
                    onOpenReminders()
                }
            )
            HomeCompactBillsCard(
                bills: viewModel.upcomingBills,
                onTap: {
                    onOpenBills()
                }
            )
        }
        .dashboardShadow()
    }

    // MARK: - Shopping Card

    private var shoppingCard: some View {
        ShoppingCardView(
            items: viewModel.shoppingItems,
            lists: viewModel.shoppingLists,
            showsAddButton: false,
            usesThinMaterial: true,
            onOpenAll: { listID in
                onOpenShopping(listID)
            },
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
            Color(.secondarySystemBackground)

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.18),
                    Color.purple.opacity(0.10),
                    Color.cyan.opacity(0.08),
                    Color(.secondarySystemBackground)
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
