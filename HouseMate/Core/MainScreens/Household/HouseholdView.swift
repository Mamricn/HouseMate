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

    var tasks: [TaskModel] {
        interactor.tasks
    }

    var shoppingItems: [ShoppingItemModel] {
        interactor.shoppingItems
    }

    var bills: [BillModel] {
        interactor.bills
    }

    init(currentUser: UserModel, members: [HouseholdMemberModel], interactor: CoreInteractor) {
        self.currentUser = currentUser
        self.members = members
        self.interactor = interactor
    }

    convenience init() {
        let container = DependencyContainer.make(environment: .mock)

        self.init(
            currentUser: UserModel.mockList[0],
            members: HouseholdMemberModel.mockList,
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
        notificationAdvance: HouseReminderAdvance
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
            notificationAdvance: notificationAdvance == .none ? nil : notificationAdvance
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
        quantity: Int
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
            isPurchased: false
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

    func clearPurchasedShoppingItems() async -> Bool {
        await actionState.perform {
            try await interactor.clearPurchasedShoppingItems()
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

    func refreshData() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchTasks(householdID: householdID, currentUserID: currentUser.id)
            try await interactor.fetchShoppingItems(householdID: householdID)
            try await interactor.fetchBills(householdID: householdID)
        }
    }
}

// MARK: - Sheet

private enum HouseholdSheet: String, Identifiable {
    case chore
    case shoppingItem
    case bill

    var id: String {
        rawValue
    }
}

struct HouseholdView: View {

    @Bindable var viewModel: HouseholdViewModel

    @State private var activeSheet: HouseholdSheet?
    @State private var toast: AppToast?

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
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 20
            ) {
                header
                scheduleCard
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Household")
                .font(
                    .system(
                        size: 30,
                        weight: .bold,
                        design: .rounded
                    )
                )

            Text("Manage your home together")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
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
            notificationAdvance in

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
                    notificationAdvance: notificationAdvance
                )
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var shoppingItemSheet: some View {
        AddShoppingItemView { name, quantity in
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
