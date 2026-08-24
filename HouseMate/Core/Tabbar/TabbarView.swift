//
//  TabbarView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//


import SwiftUI

struct TabbarView: View {

    @State private var activeTab: CustomTab = .home

    @State private var homeViewModel =
        HomeViewModel()

    @State private var householdViewModel =
        HouseholdViewModel()

    @State private var housematesViewModel =
        HousematesViewModel()

    @State private var notificationsViewModel =
        NotificationsViewModel()

    @State private var activeSheet: TabbarSheet?

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .home) {
                HomeView(
                    viewModel: homeViewModel
                )
                .customTabBarSafeArea()
            }

            Tab(value: .houseHold) {
                HouseholdView(
                    viewModel: householdViewModel
                )
                .customTabBarSafeArea()
            }

            Tab(value: .housemates) {
                HousematesView(
                    viewModel: housematesViewModel
                )
                .customTabBarSafeArea()
            }
        }
        .safeAreaInset(
            edge: .bottom,
            spacing: 0
        ) {
            customTabBarView
                .padding(.horizontal, 20)
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBarView: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                GeometryReader { geometry in
                    CustomTabBar2(
                        size: geometry.size,
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
                    .glassEffect(
                        .regular.interactive(),
                        in: .capsule
                    )
                }

                actionButton
            }
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
        .glassEffect(
            .regular.interactive(),
            in: .capsule
        )
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

        case .housemates:
            activeSheet = .housematesActions
        }
    }

    private var actionButtonAccessibilityLabel: String {
        switch activeTab {
        case .home:
            return "Open notifications"

        case .houseHold:
            return "Add household item"

        case .housemates:
            return "Create or invite"
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
    }

    // MARK: - Household Quick Actions

    private var householdQuickActionsSheet: some View {
        QuickActionsView(
            title: "Add to Household",
            subtitle: "Choose what you would like to add.",
            options: [
                QuickActionOption(
                    title: "Add Chore",
                    subtitle: "Schedule a household task",
                    systemImage: "checklist",
                    color: .blue,
                    action: {
                        activeSheet = .chore
                    }
                ),
                QuickActionOption(
                    title: "Shopping Item",
                    subtitle: "Add something to the shopping list",
                    systemImage: "cart.badge.plus",
                    color: .green,
                    action: {
                        activeSheet = .shoppingItem
                    }
                ),
                QuickActionOption(
                    title: "Add Bill",
                    subtitle: "Create a new household bill",
                    systemImage: "creditcard.fill",
                    color: .orange,
                    action: {
                        activeSheet = .bill
                    }
                )
            ]
        )
        .presentationDetents([.height(390)])
        .presentationDragIndicator(.visible)
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
            selectedDate: householdViewModel.selectedDate
        ) {
            title,
            description,
            assignedToUserId,
            dueDate,
            isAllDay,
            category in

            withAnimation {
                householdViewModel.addChore(
                    title: title,
                    description: description,
                    assignedToUserId: assignedToUserId,
                    dueDate: dueDate,
                    isAllDay: isAllDay,
                    category: category
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var shoppingItemSheet: some View {
        AddShoppingItemView { name, quantity in
            withAnimation {
                householdViewModel.addShoppingItem(
                    name: name,
                    quantity: quantity
                )
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var billSheet: some View {
        AddBillView {
            title,
            amount,
            dueDate,
            category,
            isRecurring,
            recurrence in

            withAnimation {
                householdViewModel.addBill(
                    title: title,
                    amount: amount,
                    dueDate: dueDate,
                    category: category,
                    isRecurring: isRecurring,
                    recurrence: recurrence
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Housemates Forms

    private var housemateSheet: some View {
        AddHousemateView { name, email in
            withAnimation {
                housematesViewModel.addHousemate(
                    name: name,
                    email: email
                )
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var postSheet: some View {
        AddBoardPostView { text in
            withAnimation {
                housematesViewModel.addPost(
                    text: text
                )
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var pollSheet: some View {
        AddPollView {
            question,
            options,
            expiresAt in

            withAnimation {
                housematesViewModel.addPoll(
                    question: question,
                    options: options,
                    expiresAt: expiresAt
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var reminderSheet: some View {
        AddHouseReminderView {
            title,
            details,
            firstOccurrenceDate,
            recurrence,
            category,
            reminderAdvance in

            withAnimation {
                housematesViewModel.addReminder(
                    title: title,
                    details: details,
                    firstOccurrenceDate: firstOccurrenceDate,
                    recurrence: recurrence,
                    category: category,
                    reminderAdvance: reminderAdvance
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Notification Navigation

    private func openNotification(
        _ notification: NotificationModel
    ) {
        guard let destination =
                notification.destination else {
            return
        }

        activeSheet = nil

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.25
        ) {
            switch destination {
            case .household:
                activeTab = .houseHold

            case .housemates:
                activeTab = .housemates
            }
        }
    }
}

// MARK: - Tabbar Sheet

private enum TabbarSheet: String, Identifiable {
    case notifications

    case householdActions
    case housematesActions

    case chore
    case shoppingItem
    case bill

    case housemate
    case post
    case poll
    case reminder

    var id: String {
        rawValue
    }
}

// MARK: - Custom Tab

enum CustomTab: String, CaseIterable {
    case home = "Home"
    case houseHold = "Household"
    case housemates = "Housemates"

    var symbol: String {
        switch self {
        case .home:
            return "house"

        case .houseHold:
            return "creditcard.fill"

        case .housemates:
            return "person.3.fill"
        }
    }

    var actionSymol: String {
        switch self {
        case .home:
            return "bell.fill"

        case .houseHold:
            return "plus"

        case .housemates:
            return "square.and.pencil"
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
