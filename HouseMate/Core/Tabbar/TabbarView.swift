//
//  TabbarView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//


import SwiftUI

@MainActor
struct TabbarView: View {

    private let interactor: CoreInteractor
    private let household: HouseholdModel
    private let deepLinkCoordinator: DeepLinkCoordinator

    var onSignOut: () -> Void = {}
    var onHouseholdLeft: () -> Void = {}
    var onProfileImageChanged: (String?) -> Void = { _ in }

    @State private var activeTab: CustomTab = .home
    @State private var router = AppRouter()

    @State private var homeViewModel: HomeViewModel

    @State private var householdViewModel: HouseholdViewModel

    @State private var housematesViewModel: HousematesViewModel

    @State private var notificationsViewModel: NotificationsViewModel

    @State private var activeSheet: TabbarSheet?
    @State private var toast: AppToast?
    @State private var calendarSelectedDate = Calendar.current.startOfDay(for: .now)
    @State private var calendarPrefillDate: Date?

    init(
        user: UserModel,
        household: HouseholdModel,
        members: [HouseholdMemberModel],
        interactor: CoreInteractor,
        onSignOut: @escaping () -> Void = {},
        onHouseholdLeft: @escaping () -> Void = {},
        onProfileImageChanged: @escaping (String?) -> Void = { _ in },
        deepLinkCoordinator: DeepLinkCoordinator
    ) {
        StartupDiagnostics.mark("TabbarView init started")
        self.interactor = interactor
        self.household = household
        self.deepLinkCoordinator = deepLinkCoordinator
        self.onSignOut = onSignOut
        self.onHouseholdLeft = onHouseholdLeft
        self.onProfileImageChanged = onProfileImageChanged

        let householdUsers = members.map { member in
            UserModel(
                userId: member.userId,
                name: member.displayName,
                profileImageUrl: member.profileImageUrl,
                householdId: household.householdId
            )
        }

        _homeViewModel = State(
            initialValue: HomeViewModel(
                user: user,
                members: members,
                interactor: interactor
            )
        )

        _householdViewModel = State(
            initialValue: HouseholdViewModel(
                currentUser: user,
                members: members,
                householdOwnerUserID: household.ownerUserId,
                interactor: interactor
            )
        )

        _housematesViewModel = State(
            initialValue: HousematesViewModel(
                currentUser: user,
                users: householdUsers,
                members: members,
                householdOwnerUserID: household.ownerUserId,
                interactor: interactor
            )
        )

        _notificationsViewModel = State(
            initialValue: NotificationsViewModel(
                currentUserId: user.id,
                interactor: interactor
            )
        )
        StartupDiagnostics.mark("TabbarView init finished")
    }

    init() {
        let container = DependencyContainer.make(environment: .mock)
        let interactor = CoreInteractor(container: container)

        self.init(
            user: UserModel.mockList[0],
            household: .mock,
            members: HouseholdMemberModel.mockList,
            interactor: interactor,
            deepLinkCoordinator: .shared
        )
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: $activeTab) {
                Tab(value: .home) {
                    HomeView(
                        viewModel: homeViewModel,
                        onSignOut: onSignOut,
                        onOpenSettings: {
                            router.navigate(to: .settings)
                        },
                        onOpenShopping: { listID in
                            householdViewModel.selectedShoppingListID = listID
                            router.navigate(to: .householdShopping)
                        },
                        onOpenReminders: {
                            router.navigate(to: .householdReminders(UUID()))
                        },
                        onOpenBills: {
                            router.navigate(to: .householdBills)
                        },
                        onOpenTasks: {
                            router.navigate(to: .householdCleaning)
                        }
                    )
                    .customTabBarSafeArea()
                }

                Tab(value: .houseHold) {
                    HouseholdView(
                        viewModel: householdViewModel,
                        onOpenBills: {
                            router.navigate(to: .householdBills)
                        },
                        onOpenCleaning: {
                            router.navigate(to: .householdCleaning)
                        },
                        onOpenShopping: {
                            router.navigate(to: .householdShopping)
                        },
                        onOpenPolls: {
                            router.navigate(to: .householdPolls)
                        },
                        onOpenReminders: {
                            router.navigate(to: .householdReminders(UUID()))
                        },
                        onOpenDocuments: {
                            router.navigate(to: .householdDocuments)
                        }
                    )
                    .customTabBarSafeArea()
                }

                Tab(value: .calendar) {
                    HouseholdCalendarView(
                        tasks: householdViewModel.tasks,
                        bills: householdViewModel.bills,
                        reminders: householdViewModel.reminders,
                        canLoadMoreTasks: householdViewModel.canLoadMoreTasks,
                        selectedDate: $calendarSelectedDate,
                        onOpenTasks: {
                            router.navigate(to: .householdCleaning)
                        },
                        onOpenBills: {
                            router.navigate(to: .householdBills)
                        },
                        onOpenReminders: {
                            router.navigate(to: .householdReminders(UUID()))
                        },
                        onEnsureTaskCount: { date, count in
                            await householdViewModel.ensureTasksLoaded(
                                for: date,
                                minimumCount: count
                            )
                        },
                        onRefresh: {
                            await householdViewModel.refreshData()
                        }
                    )
                    .screenAppearAnalytics(name: "CalendarView")
                    .customTabBarSafeArea()
                }
            }
            .navigationDestination(for: MainRoute.self) { route in
                destination(for: route)
            }
        }
        .safeAreaInset(
            edge: .bottom,
            spacing: 0
        ) {
            if router.path.isEmpty {
                customTabBarView
                    .padding(.horizontal, 20)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
                .screenAppearAnalytics(name: sheet.analyticsScreenName)
        }
        .overlay(alignment: .top) {
            if let toast {
                AppToastView(toast: toast)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            StartupDiagnostics.mark("TabbarView visible")
            openPendingDeepLink()
        }
        .onChange(of: deepLinkCoordinator.pending) { _, _ in
            openPendingDeepLink()
        }
        .task {
            // Home only needs these four lightweight data sources. Polls,
            // documents, board posts and notifications load on demand.
            let homeDataStartedAt = StartupDiagnostics.begin("Initial Home data")
            await homeViewModel.refreshData()
            StartupDiagnostics.end(
                "Initial Home data",
                startedAt: homeDataStartedAt
            )

            if let errorMessage = homeViewModel.actionState.errorMessage {
                showToast(
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle.fill",
                    color: .red
                )
            }

            // Push/FCM setup is not needed to draw the first screen and may
            // briefly occupy the main run loop on a cold launch.
            try? await Task.sleep(for: .seconds(1))
            if await homeViewModel.registerRemoteNotifications() {
                StartupDiagnostics.mark(
                    "Remote notifications registered for "
                        + AppEnvironment.current.rawValue
                )
            } else {
                StartupDiagnostics.mark(
                    "Remote notification registration failed: "
                        + (homeViewModel.actionState.errorMessage ?? "Unknown error")
                )
            }
        }
    }

    // MARK: - Navigation

    @ViewBuilder
    private func destination(for route: MainRoute) -> some View {
        destinationContent(for: route)
    }

    @ViewBuilder
    private func destinationContent(for route: MainRoute) -> some View {
        switch route {
        case .settings:
            SettingsView(
                user: homeViewModel.user,
                household: interactor.currentHousehold ?? household,
                onSignOut: {
                    router.reset()
                    onSignOut()
                },
                onManageHousehold: {
                    router.navigate(to: .householdSettings)
                },
                onManageAccount: {
                    router.navigate(to: .accountSettings)
                },
                onManageProfile: {
                    router.navigate(to: .profileSettings)
                },
                onNotificationPreferencesChanged: {
                    await homeViewModel.applyNotificationPreferences()
                },
                onSendTestNotification: {
                    await homeViewModel.sendTestNotification()
                },
                onAutomaticWeeklyAssignmentChanged: { isEnabled in
                    await homeViewModel.updateAutomaticWeeklyAssignment(isEnabled)
                },
                onRunWeeklyAssignmentNow: {
                    await homeViewModel.runWeeklyAssignmentNow()
                }
            )
            .screenAppearAnalytics(name: "SettingsView")

        case .householdSettings:
            HouseholdSettingsView(
                viewModel: HouseholdSettingsViewModel(
                    household: interactor.currentHousehold ?? household,
                    currentUser: homeViewModel.user,
                    interactor: interactor
                ),
                onHouseholdLeft: {
                    router.reset()
                    onHouseholdLeft()
                }
            )

        case .accountSettings:
            AccountSettingsView(
                viewModel: AccountSettingsViewModel(
                    user: homeViewModel.user,
                    household: interactor.currentHousehold ?? household,
                    interactor: interactor
                ),
                onManageHousehold: {
                    router.navigate(to: .householdSettings)
                },
                onAccountDeleted: {
                    router.reset()
                }
            )

        case .profileSettings:
            ProfileSettingsView(
                viewModel: ProfileSettingsViewModel(
                    user: homeViewModel.user,
                    interactor: interactor
                ),
                onProfileImageChanged: { imageURL in
                    applyProfileImageURL(imageURL)
                }
            )

        case .householdBills:
            BillsView(
                bills: householdViewModel.bills,
                onAdd: { activeSheet = .bill },
                onMarkAsPaid: { bill in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(bill.title) marked as paid",
                        systemImage: "checkmark.circle.fill",
                        operation: {
                            await householdViewModel.markBillAsPaid(bill)
                        }
                    )
                },
                onDelete: { bill in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(bill.title) deleted",
                        systemImage: "trash.fill",
                        operation: {
                            await householdViewModel.deleteBill(bill)
                        }
                    )
                }
            )
            .navigationTitle("Bills")
            .navigationBarTitleDisplayMode(.inline)
            .screenAppearAnalytics(name: "BillsView")

        case .householdCleaning:
            CleaningScheduleView(
                selectedDate: $householdViewModel.selectedDate,
                tasks: householdViewModel.tasks,
                members: householdViewModel.members,
                onAdd: { activeSheet = .chore },
                onToggleStatus: { task in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: task.status == .completed
                            ? "Chore marked as pending"
                            : "Chore completed",
                        systemImage: task.status == .completed
                            ? "arrow.uturn.backward.circle"
                            : "checkmark.circle.fill",
                        operation: {
                            await householdViewModel.toggleTaskStatus(task)
                        }
                    )
                },
                onDelete: { task in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(task.title) deleted",
                        systemImage: "trash.fill",
                        operation: {
                            await householdViewModel.deleteTask(task)
                        }
                    )
                },
                canLoadMore: householdViewModel.canLoadMoreTasks,
                isLoadingMore: householdViewModel.isLoadingMoreTasks,
                onEnsureTaskCount: { date, count in
                    await householdViewModel.ensureTasksLoaded(
                        for: date,
                        minimumCount: count
                    )
                }
            )
            .navigationTitle("Cleaning Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .screenAppearAnalytics(name: "CleaningScheduleView")

        case .householdShopping:
            ShoppingCollectionsView(
                items: householdViewModel.shoppingItems,
                lists: householdViewModel.shoppingLists,
                initialListID: householdViewModel.selectedShoppingListID,
                onSelect: { householdViewModel.selectedShoppingListID = $0 },
                onSaveList: { await householdViewModel.saveShoppingList($0) },
                onAdd: { activeSheet = .shoppingItem },
                onQuickAdd: { name, listID in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(name) added",
                        systemImage: "cart.badge.plus",
                        operation: {
                            await householdViewModel.addShoppingItem(
                                name: name,
                                quantity: 1,
                                listID: listID
                            )
                        }
                    )
                },
                onTogglePurchased: { item in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: item.isPurchased
                            ? "\(item.name) added back"
                            : "\(item.name) purchased",
                        systemImage: item.isPurchased
                            ? "arrow.uturn.backward.circle"
                            : "cart.badge.checkmark",
                        operation: {
                            await householdViewModel.toggleShoppingItem(item)
                        }
                    )
                },
                onDelete: { item in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(item.name) deleted",
                        systemImage: "trash.fill",
                        operation: {
                            await householdViewModel.deleteShoppingItem(item)
                        }
                    )
                },
                onClearPurchased: { listID in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "Purchased items cleared",
                        systemImage: "checkmark.circle.fill",
                        operation: {
                            await householdViewModel.clearPurchasedShoppingItems(listID: listID)
                        }
                    )
                },
                onMove: { item, listID in
                    performAction(state: householdViewModel.actionState, successMessage: "Item moved", systemImage: "cart", operation: {
                        await householdViewModel.moveShoppingItem(item, to: listID)
                    })
                }
            )
            .navigationTitle("Shopping")
            .navigationBarTitleDisplayMode(.inline)
            .screenAppearAnalytics(name: "ShoppingCollectionsView")

        case .householdPolls:
            PollsView(
                polls: householdViewModel.polls,
                currentUserId: householdViewModel.currentUser.id,
                members: householdViewModel.members,
                onAdd: { activeSheet = .poll },
                onVote: { poll, option in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "Vote submitted",
                        systemImage: "checkmark.circle.fill",
                        operation: {
                            await householdViewModel.vote(in: poll, for: option)
                        }
                    )
                },
                onRemoveVote: { poll in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "Vote removed",
                        systemImage: "arrow.uturn.backward.circle",
                        operation: {
                            await householdViewModel.removeVote(in: poll)
                        }
                    )
                },
                onClose: { poll in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "Poll closed",
                        systemImage: "checkmark.circle",
                        operation: {
                            await householdViewModel.closePoll(poll)
                        }
                    )
                },
                onDelete: { poll in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "Poll deleted",
                        systemImage: "trash.fill",
                        operation: {
                            await householdViewModel.deletePoll(poll)
                        }
                    )
                }
            )
            .navigationTitle("Polls")
            .navigationBarTitleDisplayMode(.inline)
            .screenAppearAnalytics(name: "PollsView")
            .task { await householdViewModel.loadPollsIfNeeded() }

        case .householdReminders:
            RemindersView(
                reminders: householdViewModel.reminders,
                currentUserId: householdViewModel.currentUser.id,
                householdOwnerUserId: householdViewModel.householdOwnerUserID,
                onAdd: { activeSheet = .reminder },
                onDelete: { reminder in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(reminder.title) deleted",
                        systemImage: "trash.fill",
                        operation: {
                            await householdViewModel.deleteReminder(reminder)
                        }
                    )
                },
                onUpdate: {
                    reminder,
                    title,
                    details,
                    firstOccurrenceDate,
                    recurrence,
                    category,
                    reminderAdvance in

                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(title) updated",
                        systemImage: "checkmark.circle.fill",
                        operation: {
                            await householdViewModel.updateReminder(
                                reminder,
                                title: title,
                                details: details,
                                firstOccurrenceDate: firstOccurrenceDate,
                                recurrence: recurrence,
                                category: category,
                                reminderAdvance: reminderAdvance
                            )
                        }
                    )
                }
            )
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .screenAppearAnalytics(name: "RemindersView")

        case .householdDocuments:
            DocumentsView(
                documents: householdViewModel.documents,
                currentUserId: householdViewModel.currentUser.id,
                householdOwnerUserId: householdViewModel.householdOwnerUserID,
                onAdd: { activeSheet = .document },
                onDelete: { document in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(document.title) deleted",
                        systemImage: "trash.fill",
                        operation: {
                            await householdViewModel.deleteDocument(document)
                        }
                    )
                },
                onUpdate: { document in
                    performAction(
                        state: householdViewModel.actionState,
                        successMessage: "\(document.title) updated",
                        systemImage: "checkmark.circle.fill",
                        operation: {
                            await householdViewModel.updateDocument(document)
                        }
                    )
                }
            )
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.inline)
            .screenAppearAnalytics(name: "DocumentsView")
            .task { await householdViewModel.loadDocumentsIfNeeded() }
        }
    }

    private func applyProfileImageURL(_ imageURL: String?) {
        let userID = homeViewModel.user.id
        homeViewModel.user.profileImageUrl = imageURL
        householdViewModel.currentUser.profileImageUrl = imageURL
        housematesViewModel.currentUser.profileImageUrl = imageURL

        for index in homeViewModel.members.indices
            where homeViewModel.members[index].userId == userID {
            homeViewModel.members[index].profileImageUrl = imageURL
        }

        for index in householdViewModel.members.indices
            where householdViewModel.members[index].userId == userID {
            householdViewModel.members[index].profileImageUrl = imageURL
        }

        for index in housematesViewModel.members.indices
            where housematesViewModel.members[index].userId == userID {
            housematesViewModel.members[index].profileImageUrl = imageURL
        }

        onProfileImageChanged(imageURL)
    }

    // MARK: - Custom Tab Bar

    private var customTabBarView: some View {
        HStack(spacing: 10) {
            GeometryReader { geometry in
                CustomTabBar2(
                    size: geometry.size,
                    barTint: Color.primary.opacity(0.08),
                    activeTab: $activeTab
                )
                .overlay {
                    HStack(spacing: 0) {
                        ForEach(
                            CustomTab.allCases,
                            id: \.rawValue
                        ) { tab in
                            VStack {
                                Image(
                                    systemName: tab.symbol
                                )
                                .font(.title3)

                                Text(tab.rawValue)
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                            }
                            .symbolVariant(.fill)
                            .foregroundStyle(
                                activeTab == tab
                                    ? .blue
                                    : .primary
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.primary.opacity(0.09), lineWidth: 0.75)
                }
            }

            actionButton
        }
        .frame(height: 55)

        // Badge renderuje się po całym GlassEffectContainer.
        .overlay(alignment: .topTrailing) {
            notificationBadge
                .offset(x: 5, y: -5)
                .zIndex(100)
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            handleActionButton()
        } label: {
            ZStack {
                ForEach(
                    CustomTab.allCases,
                    id: \.rawValue
                ) { tab in
                    Image(
                        systemName: tab.actionSymol
                    )
                    .font(
                        .system(
                            size: 22,
                            weight: .medium
                        )
                    )
                    .blurFade(activeTab == tab)
                }
            }
            .frame(width: 55, height: 55)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(
            .ultraThinMaterial,
            in: Circle()
        )
        .overlay {
            Circle()
                .stroke(Color.primary.opacity(0.09), lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        .animation(
            .smooth(
                duration: 0.55,
                extraBounce: 0
            ),
            value: activeTab
        )
        .accessibilityLabel(
            actionButtonAccessibilityLabel
        )
    }

    // MARK: - Notification Badge

    @ViewBuilder
    private var notificationBadge: some View {
        if activeTab == .home,
           notificationsViewModel.unreadCount > 0 {
            Text(
                badgeText(
                    notificationsViewModel.unreadCount
                )
            )
            .font(
                .system(
                    size: 10,
                    weight: .bold
                )
            )
            .foregroundStyle(.white)
            .frame(minWidth: 18, minHeight: 18)
            .padding(.horizontal, 2)
            .background {
                Capsule()
                    .fill(Color.red)
            }
            .overlay {
                Capsule()
                    .stroke(
                        Color(.systemBackground),
                        lineWidth: 2
                    )
            }
            .shadow(
                color: .black.opacity(0.20),
                radius: 3,
                y: 1
            )
            .allowsHitTesting(false)
        }
    }

    private func badgeText(_ count: Int) -> String {
        count > 99 ? "99+" : "\(count)"
    }

    // MARK: - Action Button Handling

    private func handleActionButton() {
        switch activeTab {
        case .home:
            activeSheet = .notifications

        case .houseHold:
            activeSheet = .householdActions

        case .calendar:
            activeSheet = .calendarActions
        }
    }

    private var actionButtonAccessibilityLabel: String {
        switch activeTab {
        case .home:
            return "Open notifications"

        case .houseHold:
            return "Add household item"

        case .calendar:
            return "Add calendar item"
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetContent(
        for sheet: TabbarSheet
    ) -> some View {
        switch sheet {
        case .notifications:
            notificationsSheet

        case .householdActions:
            householdQuickActionsSheet

        case .calendarActions:
            calendarQuickActionsSheet

        case .housematesActions:
            housematesQuickActionsSheet

        case .chore:
            choreSheet

        case .shoppingItem:
            shoppingItemSheet

        case .bill:
            billSheet

        case .housemate:
            housemateSheet

        case .post:
            postSheet

        case .poll:
            pollSheet

        case .reminder:
            reminderSheet

        case .document:
            documentSheet
        }
    }

    // MARK: - Notifications

    private var notificationsSheet: some View {
        NotificationsView(
            viewModel: notificationsViewModel,
            onOpenNotification: { notification in
                openNotification(notification)
            }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    // MARK: - Household Quick Actions

    private var householdQuickActionsSheet: some View {
        QuickActionsView(
            title: "Add to Household",
            subtitle: "Choose what you would like to add.",
            options: [
                QuickActionOption(
                    title: "Add Chore",
                    subtitle: "Assign a household task",
                    systemImage: "checklist",
                    color: .blue,
                    action: {
                        calendarPrefillDate = nil
                        activeSheet = .chore
                    }
                ),
                QuickActionOption(
                    title: "Shopping Item",
                    subtitle: "Add to the shopping list",
                    systemImage: "cart.badge.plus",
                    color: .green,
                    action: {
                        calendarPrefillDate = nil
                        activeSheet = .shoppingItem
                    }
                ),
                QuickActionOption(
                    title: "Add Bill",
                    subtitle: "Track a household bill",
                    systemImage: "creditcard.fill",
                    color: .orange,
                    action: {
                        calendarPrefillDate = nil
                        activeSheet = .bill
                    }
                ),
                QuickActionOption(
                    title: "Add Reminder",
                    subtitle: "Plan a reminder",
                    systemImage: "bell.badge.fill",
                    color: .purple,
                    action: {
                        calendarPrefillDate = nil
                        activeSheet = .reminder
                    }
                ),
                QuickActionOption(
                    title: "Create Poll",
                    subtitle: "Ask your household",
                    systemImage: "chart.bar.doc.horizontal",
                    color: .indigo,
                    action: {
                        calendarPrefillDate = nil
                        activeSheet = .poll
                    }
                ),
                QuickActionOption(
                    title: "Add Document",
                    subtitle: "Save a receipt or file",
                    systemImage: "doc.badge.plus",
                    color: .cyan,
                    action: {
                        calendarPrefillDate = nil
                        activeSheet = .document
                    }
                )
            ],
            layout: .grid
        )
        .presentationDetents([.height(505)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    // MARK: - Calendar Quick Actions

    private var calendarQuickActionsSheet: some View {
        QuickActionsView(
            title: "Schedule",
            subtitle: "Add something for \(calendarSelectedDate.formatted(.dateTime.day().month(.wide))).",
            options: [
                QuickActionOption(
                    title: "Schedule Chore",
                    subtitle: "Assign a task for this day",
                    systemImage: "checklist",
                    color: .blue,
                    action: {
                        calendarPrefillDate = calendarSelectedDate
                        activeSheet = .chore
                    }
                ),
                QuickActionOption(
                    title: "Add Bill",
                    subtitle: "Set a bill due on this day",
                    systemImage: "creditcard.fill",
                    color: .orange,
                    action: {
                        calendarPrefillDate = calendarSelectedDate
                        activeSheet = .bill
                    }
                ),
                QuickActionOption(
                    title: "Add Reminder",
                    subtitle: "Create a reminder for this day",
                    systemImage: "bell.badge.fill",
                    color: .purple,
                    action: {
                        calendarPrefillDate = calendarSelectedDate
                        activeSheet = .reminder
                    }
                )
            ],
            layout: .themedList
        )
        .presentationDetents([.height(390)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    // MARK: - Housemates Quick Actions

    private var housematesQuickActionsSheet: some View {
        QuickActionsView(
            title: "Create",
            subtitle: "Share something with your housemates.",
            options: [
                QuickActionOption(
                    title: "New Post",
                    subtitle: "Post a message on the household board",
                    systemImage: "text.bubble.fill",
                    color: .blue,
                    action: {
                        activeSheet = .post
                    }
                ),
                QuickActionOption(
                    title: "New Poll",
                    subtitle: "Ask your housemates a question",
                    systemImage: "chart.bar.doc.horizontal",
                    color: .purple,
                    action: {
                        activeSheet = .poll
                    }
                ),
                QuickActionOption(
                    title: "New Reminder",
                    subtitle: "Add a recurring house reminder",
                    systemImage: "bell.badge.fill",
                    color: .orange,
                    action: {
                        activeSheet = .reminder
                    }
                ),
                QuickActionOption(
                    title: "Invite Housemate",
                    subtitle: "Invite someone to join your home",
                    systemImage: "person.badge.plus",
                    color: .green,
                    action: {
                        activeSheet = .housemate
                    }
                )
            ]
        )
        .presentationDetents([.height(470)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Household Forms

    private var choreSheet: some View {
        AddChoreView(
            members: householdViewModel.members,
            selectedDate: calendarPrefillDate ?? householdViewModel.selectedDate
        ) {
            title,
            description,
            assignedToUserId,
            dueDate,
            isAllDay,
            category,
            notificationAdvance,
            participatesInWeeklyRotation in

            performAction(
                state: householdViewModel.actionState,
                successMessage: "\(title) scheduled",
                systemImage: "calendar.badge.plus",
                operation: {
                    await householdViewModel.addChore(
                    title: title,
                    description: description,
                    assignedToUserId: assignedToUserId,
                    dueDate: dueDate,
                    isAllDay: isAllDay,
                    category: category,
                    notificationAdvance: notificationAdvance,
                    participatesInWeeklyRotation: participatesInWeeklyRotation
                )
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var shoppingItemSheet: some View {
        AddShoppingItemView(lists: householdViewModel.shoppingLists, initialListID: householdViewModel.selectedShoppingListID, onListSelected: { householdViewModel.selectedShoppingListID = $0 }) { name, quantity in
            performAction(
                state: householdViewModel.actionState,
                successMessage: "\(name) added",
                systemImage: "cart.badge.plus",
                operation: {
                    await householdViewModel.addShoppingItem(
                    name: name,
                    quantity: quantity
                )
                }
            )
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var billSheet: some View {
        AddBillView(initialDueDate: calendarPrefillDate ?? .now) {
            title,
            amount,
            dueDate,
            category,
            isRecurring,
            recurrence,
            notificationAdvance in

            performAction(
                state: householdViewModel.actionState,
                successMessage: "\(title) added",
                systemImage: "creditcard.fill",
                operation: {
                    await householdViewModel.addBill(
                    title: title,
                    amount: amount,
                    dueDate: dueDate,
                    category: category,
                    isRecurring: isRecurring,
                    recurrence: recurrence,
                    notificationAdvance: notificationAdvance
                )
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Housemates Forms

    private var housemateSheet: some View {
        AddHousemateView(household: household)
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.visible)
    }

    private var postSheet: some View {
        AddBoardPostView { text in
            performAction(
                state: housematesViewModel.actionState,
                successMessage: "Post added",
                systemImage: "text.bubble.fill",
                operation: {
                    await housematesViewModel.addPost(
                    text: text
                )
                }
            )
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var pollSheet: some View {
        AddPollView {
            question,
            options,
            expiresAt in

            performAction(
                state: householdViewModel.actionState,
                successMessage: "Poll created",
                systemImage: "chart.bar.doc.horizontal",
                operation: {
                    await householdViewModel.addPoll(
                    question: question,
                    options: options,
                    expiresAt: expiresAt
                )
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var reminderSheet: some View {
        AddHouseReminderView(initialDate: calendarPrefillDate ?? .now) {
            title,
            details,
            firstOccurrenceDate,
            recurrence,
            category,
            reminderAdvance in

            performAction(
                state: householdViewModel.actionState,
                successMessage: "\(title) added",
                systemImage: "bell.badge.fill",
                operation: {
                    await householdViewModel.addReminder(
                    title: title,
                    details: details,
                    firstOccurrenceDate: firstOccurrenceDate,
                    recurrence: recurrence,
                    category: category,
                    reminderAdvance: reminderAdvance
                )
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var documentSheet: some View {
        AddDocumentView {
            title,
            category,
            notes,
            storeName,
            amount,
            purchaseDate,
            warrantyExpiresAt,
            serialNumber,
            attachment in

            performAction(
                state: householdViewModel.actionState,
                successMessage: "\(title) added",
                systemImage: "doc.badge.plus",
                operation: {
                    await householdViewModel.addDocument(
                        title: title,
                        category: category,
                        notes: notes,
                        storeName: storeName,
                        amount: amount,
                        purchaseDate: purchaseDate,
                        warrantyExpiresAt: warrantyExpiresAt,
                        serialNumber: serialNumber,
                        attachment: attachment
                    )
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func performAction(state: AsyncActionState, successMessage: String, systemImage: String, operation: @escaping @MainActor () async -> Bool) {
        Task {
            let succeeded = await operation()

            showToast(
                message: succeeded
                    ? successMessage
                    : state.errorMessage ?? "Something went wrong. Please try again.",
                systemImage: succeeded ? systemImage : "exclamationmark.triangle.fill",
                color: succeeded ? .green : .red
            )
        }
    }

    private func showToast(message: String, systemImage: String, color: Color) {
        let newToast = AppToast(
            message: message,
            systemImage: systemImage,
            color: color
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            toast = newToast
        }

        Task {
            try? await Task.sleep(for: .seconds(2.2))

            guard toast?.id == newToast.id else {
                return
            }

            withAnimation(.easeOut(duration: 0.22)) {
                toast = nil
            }
        }
    }

    // MARK: - Notification Navigation

    private func openNotification(
        _ notification: NotificationModel
    ) {
        // The type is authoritative so historical notifications with the old
        // generic destination still open the correct feature.
        let destination = notification.type.defaultDestination

        navigate(to: destination, waitsForSheetDismissal: true)
    }

    private func openSystemNotification(userInfo: [AnyHashable: Any]) {
        deepLinkCoordinator.handle(notificationUserInfo: userInfo)
    }

    private func openPendingDeepLink() {
        guard let deepLink = deepLinkCoordinator.pending else { return }

        guard case let .notification(destination, householdID, _) = deepLink else {
            // Joining another household is only valid in onboarding.
            deepLinkCoordinator.consume(deepLink)
            return
        }

        if let householdID,
           householdID != household.householdId {
            deepLinkCoordinator.consume(deepLink)
            return
        }

        navigate(to: destination, waitsForSheetDismissal: activeSheet != nil)
        deepLinkCoordinator.consume(deepLink)
    }

    private func navigate(
        to destination: NotificationDestination,
        waitsForSheetDismissal: Bool
    ) {
        activeSheet = nil
        router.reset()
        activeTab = .houseHold

        guard let route = route(for: destination) else {
            return
        }

        Task { @MainActor in
            // First establish Household as the destination's parent tab,
            // then push after TabView/sheet transitions have settled.
            if waitsForSheetDismissal {
                try? await Task.sleep(for: .milliseconds(400))
            } else {
                await Task.yield()
                try? await Task.sleep(for: .milliseconds(100))
            }

            router.navigate(to: route, trackInteraction: false)
        }
    }

    private func route(
        for destination: NotificationDestination
    ) -> MainRoute? {
        switch destination {
        case .household, .housemates:
            return nil
        case .tasks:
            return .householdCleaning
        case .shopping:
            return .householdShopping
        case .bills:
            return .householdBills
        case .polls:
            return .householdPolls
        case .reminders:
            return .householdReminders(UUID())
        case .documents:
            return .householdDocuments
        }
    }
}

// MARK: - Tabbar Sheet

private enum TabbarSheet: String, Identifiable {
    case notifications

    case householdActions
    case calendarActions
    case housematesActions

    case chore
    case shoppingItem
    case bill

    case housemate
    case post
    case poll
    case reminder
    case document

    var id: String {
        rawValue
    }

    var analyticsScreenName: String {
        switch self {
        case .notifications: "NotificationsView"
        case .householdActions: "HouseholdQuickActionsView"
        case .calendarActions: "CalendarQuickActionsView"
        case .housematesActions: "HousematesQuickActionsView"
        case .chore: "AddChoreView"
        case .shoppingItem: "AddShoppingItemView"
        case .bill: "AddBillView"
        case .housemate: "AddHousemateView"
        case .post: "AddBoardPostView"
        case .poll: "AddPollView"
        case .reminder: "AddHouseReminderView"
        case .document: "AddDocumentView"
        }
    }
}

// MARK: - Custom Tab

enum CustomTab: String, CaseIterable {
    case home = "Home"
    case houseHold = "Household"
    case calendar = "Calendar"

    var symbol: String {
        switch self {
        case .home:
            return "house"

        case .houseHold:
            return "creditcard.fill"

        case .calendar:
            return "calendar"
        }
    }

    var actionSymol: String {
        switch self {
        case .home:
            return "bell.fill"

        case .houseHold:
            return "plus"

        case .calendar:
            return "calendar.badge.plus"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

// MARK: - Preview

#Preview {
    TabbarView()
}
