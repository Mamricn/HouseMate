//
//  HouseholdView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI

@Observable
@MainActor
final class HouseholdViewModel {

    private let interactor: CoreInteractor
    let actionState = AsyncActionState()

    var selectedDate: Date = .now

    var currentUser: UserModel

    var members: [HouseholdMemberModel]

    let householdOwnerUserID: String

    var tasks: [TaskModel] {
        interactor.tasks
    }

    var shoppingItems: [ShoppingItemModel] {
        interactor.shoppingItems
    }
    var shoppingLists: [ShoppingCollection] { interactor.shoppingLists }
    var selectedShoppingListID = "groceries"
    func saveShoppingList(_ list: ShoppingCollection) async -> Bool {
        guard let id = currentUser.householdId else { return false }
        return await actionState.perform { try await interactor.saveShoppingList(list, householdID: id) }
    }
    func moveShoppingItem(_ item: ShoppingItemModel, to listID: String) async -> Bool {
        await actionState.perform { try await interactor.moveShoppingItem(item, to: listID) }
    }

    var bills: [BillModel] {
        interactor.bills
    }

    var polls: [PollModel] {
        interactor.polls
    }

    var reminders: [HouseReminderModel] {
        interactor.houseReminders
    }

    var documents: [HouseholdDocumentModel] {
        interactor.householdDocuments
    }

    init(currentUser: UserModel, members: [HouseholdMemberModel], householdOwnerUserID: String, interactor: CoreInteractor) {
        self.currentUser = currentUser
        self.members = members
        self.householdOwnerUserID = householdOwnerUserID
        self.interactor = interactor
    }

    convenience init() {
        let container = DependencyContainer.make(environment: .mock)

        self.init(
            currentUser: UserModel.mockList[0],
            members: HouseholdMemberModel.mockList,
            householdOwnerUserID: HouseholdModel.mock.ownerUserId,
            interactor: CoreInteractor(container: container)
        )
    }

    // MARK: - Task Actions

    func addChore(
        title: String,
        description: String?,
        assignedToUserId: String,
        dueDate: Date,
        isAllDay: Bool,
        category: TaskCategory,
        notificationAdvance: HouseReminderAdvance,
        participatesInWeeklyRotation: Bool
    ) async -> Bool {
        guard let householdId = currentUser.householdId else {
            return false
        }

        let newTask = TaskModel(
            taskId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            title: title,
            description: description,
            assignedToUserId: assignedToUserId,
            createdByUserId: currentUser.id,
            dueDate: dueDate,
            isAllDay: isAllDay,
            status: .pending,
            category: category,
            notificationAdvance: notificationAdvance == .none ? nil : notificationAdvance,
            participatesInWeeklyRotation: participatesInWeeklyRotation
        )

        return await actionState.perform {
            try await interactor.createTask(newTask)
        }
    }

    func toggleTaskStatus(_ task: TaskModel) async -> Bool {
        await actionState.perform {
            try await interactor.toggleTaskStatus(task)
        }
    }

    func deleteTask(_ task: TaskModel) async -> Bool {
        await actionState.perform {
            try await interactor.deleteTask(task)
        }
    }

    func fetchTasks() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchTasks(householdID: householdID, currentUserID: currentUser.id)
        }
    }

    // MARK: - Shopping Actions

    func addShoppingItem(
        name: String,
        quantity: Int,
        listID: String? = nil
    ) async -> Bool {
        guard let householdId = currentUser.householdId else {
            return false
        }

        let newItem = ShoppingItemModel(
            itemId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            name: name,
            quantity: quantity,
            addedByUserId: currentUser.id,
            isPurchased: false,
            listId: listID ?? selectedShoppingListID
        )

        return await actionState.perform {
            try await interactor.createShoppingItem(newItem)
        }
    }

    func toggleShoppingItem(
        _ item: ShoppingItemModel
    ) async -> Bool {
        await actionState.perform {
            try await interactor.toggleShoppingItemPurchased(item)
        }
    }

    func deleteShoppingItem(
        _ item: ShoppingItemModel
    ) async -> Bool {
        await actionState.perform {
            try await interactor.deleteShoppingItem(item)
        }
    }

    func clearPurchasedShoppingItems(listID: String? = nil) async -> Bool {
        await actionState.perform {
            try await interactor.clearPurchasedShoppingItems(listID: listID)
        }
    }

    func fetchShoppingItems() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchShoppingItems(householdID: householdID)
        }
    }

    // MARK: - Bill Actions

    func addBill(
        title: String,
        amount: Double,
        dueDate: Date,
        category: BillCategory,
        isRecurring: Bool,
        recurrence: BillRecurrence?,
        notificationAdvance: HouseReminderAdvance
    ) async -> Bool {
        guard let householdId = currentUser.householdId else {
            return false
        }

        let billID = UUID().uuidString

        let newBill = BillModel(
            billId: billID,
            householdId: householdId,
            createdAt: .now,
            title: title,
            amount: amount,
            dueDate: dueDate,
            category: category,
            createdByUserId: currentUser.id,
            paidByUserId: nil,
            status: .upcoming,
            isRecurring: isRecurring,
            recurrence: recurrence,
            recurrenceSeriesId: isRecurring ? billID : nil,
            notificationAdvance: notificationAdvance == .none ? nil : notificationAdvance
        )

        return await actionState.perform {
            try await interactor.createBill(newBill)
        }
    }

    func markBillAsPaid(_ bill: BillModel) async -> Bool {
        await actionState.perform {
            try await interactor.markBillAsPaid(bill, paidByUserID: currentUser.id)
        }
    }

    func deleteBill(_ bill: BillModel) async -> Bool {
        await actionState.perform {
            try await interactor.deleteBill(bill)
        }
    }

    func fetchBills() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchBills(householdID: householdID)
        }
    }

    // MARK: - Poll Actions

    func addPoll(question: String, options: [String], expiresAt: Date?) async -> Bool {
        guard let householdId = currentUser.householdId else { return false }

        let poll = PollModel(
            pollId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            createdByUserId: currentUser.id,
            question: question,
            options: options.map { PollOptionModel(optionId: UUID().uuidString, text: $0) },
            votesByUserId: [:],
            status: .active,
            expiresAt: expiresAt
        )

        return await actionState.perform {
            try await interactor.createPoll(poll)
        }
    }

    func vote(in poll: PollModel, for option: PollOptionModel) async -> Bool {
        await actionState.perform {
            try await interactor.vote(in: poll, option: option, userID: currentUser.id)
        }
    }

    func removeVote(in poll: PollModel) async -> Bool {
        await actionState.perform {
            try await interactor.removeVote(in: poll, userID: currentUser.id)
        }
    }

    func closePoll(_ poll: PollModel) async -> Bool {
        await actionState.perform {
            try await interactor.closePoll(poll, currentUserID: currentUser.id)
        }
    }

    func deletePoll(_ poll: PollModel) async -> Bool {
        await actionState.perform {
            try await interactor.deletePoll(poll, currentUserID: currentUser.id)
        }
    }

    // MARK: - Reminder Actions

    func addReminder(
        title: String,
        details: String?,
        firstOccurrenceDate: Date,
        recurrence: HouseReminderRecurrence,
        category: HouseReminderCategory,
        reminderAdvance: HouseReminderAdvance
    ) async -> Bool {
        guard let householdId = currentUser.householdId else { return false }

        let reminder = HouseReminderModel(
            reminderId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            createdByUserId: currentUser.id,
            title: title,
            details: details,
            firstOccurrenceDate: firstOccurrenceDate,
            recurrence: recurrence,
            category: category,
            reminderAdvance: reminderAdvance
        )

        return await actionState.perform {
            try await interactor.createHouseReminder(reminder)
        }
    }

    func deleteReminder(_ reminder: HouseReminderModel) async -> Bool {
        await actionState.perform {
            try await interactor.deleteHouseReminder(
                reminder,
                currentUserID: currentUser.id,
                ownerUserID: householdOwnerUserID
            )
        }
    }

    func updateReminder(
        _ reminder: HouseReminderModel,
        title: String,
        details: String?,
        firstOccurrenceDate: Date,
        recurrence: HouseReminderRecurrence,
        category: HouseReminderCategory,
        reminderAdvance: HouseReminderAdvance
    ) async -> Bool {
        var updatedReminder = reminder
        updatedReminder.title = title
        updatedReminder.details = details
        updatedReminder.firstOccurrenceDate = firstOccurrenceDate
        updatedReminder.recurrence = recurrence
        updatedReminder.category = category
        updatedReminder.reminderAdvance = reminderAdvance

        return await actionState.perform {
            try await interactor.updateHouseReminder(
                updatedReminder,
                currentUserID: currentUser.id,
                ownerUserID: householdOwnerUserID
            )
        }
    }

    // MARK: - Document Actions

    func addDocument(
        title: String,
        category: HouseholdDocumentCategory,
        notes: String?,
        storeName: String?,
        amount: Double?,
        purchaseDate: Date?,
        warrantyExpiresAt: Date?,
        serialNumber: String?,
        attachment: DocumentAttachmentDraft
    ) async -> Bool {
        guard let householdId = currentUser.householdId else { return false }
        let document = HouseholdDocumentModel(
            documentId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            createdByUserId: currentUser.id,
            title: title,
            category: category,
            notes: notes,
            fileName: attachment.fileName,
            fileURL: "",
            storagePath: "",
            contentType: attachment.contentType,
            storeName: storeName,
            amount: amount,
            purchaseDate: purchaseDate,
            warrantyExpiresAt: warrantyExpiresAt,
            serialNumber: serialNumber
        )
        return await actionState.perform {
            try await interactor.createHouseholdDocument(document, attachment: attachment)
        }
    }

    func deleteDocument(_ document: HouseholdDocumentModel) async -> Bool {
        guard document.createdByUserId == currentUser.id
                || currentUser.id == householdOwnerUserID else { return false }
        return await actionState.perform {
            try await interactor.deleteHouseholdDocument(document)
        }
    }

    func updateDocument(_ document: HouseholdDocumentModel) async -> Bool {
        guard document.createdByUserId == currentUser.id
                || currentUser.id == householdOwnerUserID else { return false }
        return await actionState.perform {
            try await interactor.updateHouseholdDocument(document)
        }
    }

    func refreshData() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchTasks(householdID: householdID, currentUserID: currentUser.id)
            try await interactor.fetchShoppingItems(householdID: householdID)
            try await interactor.fetchBills(householdID: householdID)
            try await interactor.fetchPolls(householdID: householdID)
            try await interactor.fetchHouseReminders(householdID: householdID)
            try await interactor.fetchHouseholdDocuments(householdID: householdID)
        }
    }
}

// MARK: - Sheet

private enum HouseholdSheet: String, Identifiable {
    case chore
    case shoppingItem
    case bill
    case poll
    case reminder

    var id: String {
        rawValue
    }
}

private enum HouseholdFeature: String, Hashable {
    case bills
    case cleaning
    case shopping
    case polls
    case reminders
    case documents
}

struct HouseholdView: View {

    @Bindable var viewModel: HouseholdViewModel
    var onOpenBills: () -> Void = {}
    var onOpenCleaning: () -> Void = {}
    var onOpenShopping: () -> Void = {}
    var onOpenPolls: () -> Void = {}
    var onOpenReminders: () -> Void = {}
    var onOpenDocuments: () -> Void = {}

    @State private var activeSheet: HouseholdSheet?
    @State private var toast: AppToast?
    @State private var isHeaderElevated = false

    var body: some View {
        ZStack {
            backgroundGradient
            content
            toastOverlay
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            householdHeader
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 18)
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

            ScrollView {
                LazyVStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    primaryFeatures
                    secondaryFeatures
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 35)
            }
            .houseMatePullToRefresh {
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
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 4
            } action: { _, isScrolled in
                isHeaderElevated = isScrolled
            }
        }
    }

    private var householdHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Household")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Everything your home needs, in one place")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var primaryFeatures: some View {
        HStack(alignment: .top, spacing: 12) {
            featureLink(
                .bills,
                title: "Bills",
                systemImage: "creditcard.fill",
                assetName: "HouseholdBills",
                colors: [.blue, .indigo],
                isLarge: true
            )

            featureLink(
                .cleaning,
                title: "Cleaning",
                systemImage: "sparkles",
                assetName: "HouseholdCleaning",
                colors: [.cyan, .blue],
                isLarge: true
            )
        }
    }

    private var secondaryFeatures: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            featureLink(
                .shopping,
                title: "Shopping",
                systemImage: "cart.fill",
                assetName: "HouseholdShopping",
                colors: [.mint, .teal]
            )

            featureLink(
                .polls,
                title: "Polls",
                systemImage: "chart.bar.fill",
                assetName: "HouseholdPolls",
                colors: [.purple, .indigo]
            )

            featureLink(
                .reminders,
                title: "Reminders",
                systemImage: "bell.fill",
                assetName: "HouseholdReminders",
                colors: [.orange, .pink]
            )

            featureLink(
                .documents,
                title: "Documents",
                systemImage: "folder.fill",
                assetName: "HouseholdDocuments",
                colors: [.blue, .cyan]
            )
        }
    }

    private func featureLink(
        _ feature: HouseholdFeature,
        title: String,
        systemImage: String,
        assetName: String,
        colors: [Color],
        isLarge: Bool = false
    ) -> some View {
        Group {
            if feature == .bills || feature == .cleaning || feature == .shopping || feature == .polls || feature == .reminders || feature == .documents {
                Button(action: featureAction(for: feature)) {
                    featureTile(
                        title: title,
                        systemImage: systemImage,
                        assetName: assetName,
                        colors: colors,
                        isLarge: isLarge
                    )
                }
            } else {
                NavigationLink {
                    featureDestination(feature)
                } label: {
                    featureTile(
                        title: title,
                        systemImage: systemImage,
                        assetName: assetName,
                        colors: colors,
                        isLarge: isLarge
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func featureAction(for feature: HouseholdFeature) -> () -> Void {
        switch feature {
        case .bills: onOpenBills
        case .cleaning: onOpenCleaning
        case .shopping: onOpenShopping
        case .polls: onOpenPolls
        case .reminders: onOpenReminders
        case .documents: onOpenDocuments
        }
    }

    private func featureTile(
        title: String,
        systemImage: String,
        assetName: String,
        colors: [Color],
        isLarge: Bool
    ) -> some View {
            HouseholdFeatureTile(
                title: title,
                systemImage: systemImage,
                assetName: assetName,
                colors: colors,
                isLarge: isLarge
            )
    }

    @ViewBuilder
    private func featureDestination(_ feature: HouseholdFeature) -> some View {
        ZStack {
            backgroundGradient

            switch feature {
            case .bills:
                BillsView(
                    bills: viewModel.bills,
                    onAdd: { activeSheet = .bill },
                    onMarkAsPaid: { bill in
                        performAction(
                            successMessage: "\(bill.title) marked as paid",
                            systemImage: "checkmark.circle.fill",
                            color: .green,
                            operation: { await viewModel.markBillAsPaid(bill) }
                        )
                    },
                    onDelete: { bill in
                        performAction(
                            successMessage: "\(bill.title) deleted",
                            systemImage: "trash.fill",
                            color: .red,
                            operation: { await viewModel.deleteBill(bill) }
                        )
                    }
                )
                    .navigationTitle("Bills")

            case .cleaning:
                detailScrollView { scheduleCard }
                    .navigationTitle("Cleaning Schedule")

            case .shopping:
                detailScrollView { shoppingCard }
                    .navigationTitle("Shopping List")

            case .polls:
                detailScrollView { pollsCard }
                    .navigationTitle("Polls")

            case .reminders:
                detailScrollView { remindersCard }
                    .navigationTitle("Reminders")

            case .documents:
                unavailableFeature("Documents", systemImage: "folder.fill")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailScrollView<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            content()
                .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    private func unavailableFeature(
        _ title: String,
        systemImage: String
    ) -> some View {
        ContentUnavailableView(
            "\(title) are moving here",
            systemImage: systemImage,
            description: Text("This section will be connected in the next UI step.")
        )
    }

    // MARK: - Schedule

    private var scheduleCard: some View {
        ScheduleCardView(
            selectedDate: $viewModel.selectedDate,
            tasks: viewModel.tasks,
            members: viewModel.members,
            showsAddButton: true,
            onAdd: {
                activeSheet = .chore
            },
            onToggleStatus: { task in
                performAction(
                    successMessage: task.status == .completed
                        ? "Chore marked as pending"
                        : "Chore completed",
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
            },
            onDelete: { task in
                performAction(
                    successMessage: "\(task.title) deleted",
                    systemImage: "calendar.badge.minus",
                    color: .red,
                    operation: {
                        await viewModel.deleteTask(task)
                    }
                )
            }
        )
        .householdCardShadow()
    }

    // MARK: - Shopping

    private var shoppingCard: some View {
        ShoppingCardView(
            items: viewModel.shoppingItems,
            showsAddButton: true,
            onAdd: {
                activeSheet = .shoppingItem
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
            },
            onDelete: { item in
                performAction(
                    successMessage: "\(item.name) deleted",
                    systemImage: "trash.fill",
                    color: .red,
                    operation: {
                        await viewModel.deleteShoppingItem(item)
                    }
                )
            },
            onClearPurchased: {
                performAction(
                    successMessage: "Purchased items cleared",
                    systemImage: "checkmark.circle.fill",
                    color: .green,
                    operation: {
                        await viewModel.clearPurchasedShoppingItems()
                    }
                )
            }
        )
        .householdCardShadow()
    }

    // MARK: - Bills

    private var billsCard: some View {
        BillsCardView(
            bills: viewModel.bills,
            title: "All Bills",
            showsAddButton: true,
            onAdd: {
                activeSheet = .bill
            },
            onMarkAsPaid: { bill in
                performAction(
                    successMessage: "\(bill.title) marked as paid",
                    systemImage: "checkmark.circle.fill",
                    color: .green,
                    operation: {
                        await viewModel.markBillAsPaid(bill)
                    }
                )
            },
            onDelete: { bill in
                performAction(
                    successMessage: "\(bill.title) deleted",
                    systemImage: "trash.fill",
                    color: .red,
                    operation: {
                        await viewModel.deleteBill(bill)
                    }
                )
            }
        )
        .householdCardShadow()
    }

    // MARK: - Polls

    private var pollsCard: some View {
        HouseholdPollsCardView(
            polls: viewModel.polls,
            currentUserId: viewModel.currentUser.id,
            members: viewModel.members,
            showsAddButton: true,
            onAdd: { activeSheet = .poll },
            onVote: { poll, option in
                performAction(
                    successMessage: "Vote submitted",
                    systemImage: "checkmark.circle.fill",
                    color: .green,
                    operation: { await viewModel.vote(in: poll, for: option) }
                )
            },
            onClose: { poll in
                performAction(
                    successMessage: "Poll closed",
                    systemImage: "checkmark.circle",
                    color: .orange,
                    operation: { await viewModel.closePoll(poll) }
                )
            },
            onDelete: { poll in
                performAction(
                    successMessage: "Poll deleted",
                    systemImage: "trash.fill",
                    color: .red,
                    operation: { await viewModel.deletePoll(poll) }
                )
            }
        )
        .householdCardShadow()
    }

    // MARK: - Reminders

    private var remindersCard: some View {
        HouseRemindersCardView(
            reminders: viewModel.reminders,
            currentUserId: viewModel.currentUser.id,
            householdOwnerUserId: viewModel.householdOwnerUserID,
            showsAddButton: true,
            onAdd: { activeSheet = .reminder },
            onDelete: { reminder in
                performAction(
                    successMessage: "\(reminder.title) deleted",
                    systemImage: "trash.fill",
                    color: .red,
                    operation: { await viewModel.deleteReminder(reminder) }
                )
            }
        )
        .householdCardShadow()
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetContent(
        for sheet: HouseholdSheet
    ) -> some View {
        switch sheet {
        case .chore:
            choreSheet

        case .shoppingItem:
            shoppingItemSheet

        case .bill:
            billSheet

        case .poll:
            pollSheet

        case .reminder:
            reminderSheet
        }
    }

    private var choreSheet: some View {
        AddChoreView(
            members: viewModel.members,
            selectedDate: viewModel.selectedDate
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
                successMessage: "\(title) scheduled",
                systemImage: "calendar.badge.plus",
                color: .green,
                operation: {
                    await viewModel.addChore(
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
        AddShoppingItemView(lists: viewModel.shoppingLists, initialListID: viewModel.selectedShoppingListID, onListSelected: { viewModel.selectedShoppingListID = $0 }) { name, quantity in
            performAction(
                successMessage: "\(name) added",
                systemImage: "cart.badge.plus",
                color: .green,
                operation: {
                    await viewModel.addShoppingItem(
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
        AddBillView {
            title,
            amount,
            dueDate,
            category,
            isRecurring,
            recurrence,
            notificationAdvance in

            performAction(
                successMessage: "\(title) added",
                systemImage: "creditcard.fill",
                color: .green,
                operation: {
                    await viewModel.addBill(
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

    private var pollSheet: some View {
        AddPollView { question, options, expiresAt in
            performAction(
                successMessage: "Poll created",
                systemImage: "chart.bar.doc.horizontal",
                color: .green,
                operation: {
                    await viewModel.addPoll(
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
        AddHouseReminderView {
            title,
            details,
            firstOccurrenceDate,
            recurrence,
            category,
            reminderAdvance in

            performAction(
                successMessage: "\(title) added",
                systemImage: "bell.badge.fill",
                color: .green,
                operation: {
                    await viewModel.addReminder(
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

    private func showToast(
        message: String,
        systemImage: String,
        color: Color
    ) {
        let newToast = AppToast(
            message: message,
            systemImage: systemImage,
            color: color
        )

        withAnimation(.spring(response: 0.4)) {
            toast = newToast
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.5
        ) {
            guard toast?.id == newToast.id else {
                return
            }

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

// MARK: - Card Shadow

private extension View {

    func householdCardShadow() -> some View {
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
    HouseholdView(
        viewModel: HouseholdViewModel()
    )
}
