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

    private var didLoadPolls = false
    private var didLoadDocuments = false

    var tasks: [TaskModel] {
        interactor.tasks
    }

    var canLoadMoreTasks: Bool { interactor.canLoadMoreTasks }
    var isLoadingMoreTasks: Bool { interactor.isLoadingMoreTasks }

    var shoppingItems: [ShoppingItemModel] {
        interactor.shoppingItems
    }
    var shoppingLists: [ShoppingCollection] { interactor.shoppingLists }
    var selectedShoppingListID = "groceries"
    func saveShoppingList(_ list: ShoppingCollection) async -> Bool {
        guard let id = currentUser.householdId else { return false }
        let parameters = list.eventParameters
        interactor.trackEvent(Event.start(operation: .saveShoppingList, parameters: parameters))
        do {
            try await actionState.run { try await interactor.saveShoppingList(list, householdID: id) }
            interactor.trackEvent(Event.success(operation: .saveShoppingList, parameters: parameters)); return true
        } catch { interactor.trackEvent(Event.fail(operation: .saveShoppingList, error: error, parameters: parameters)); return false }
    }
    func moveShoppingItem(_ item: ShoppingItemModel, to listID: String) async -> Bool {
        let parameters = item.eventParameters.merging(["target_list_id": listID]) { current, _ in current }
        interactor.trackEvent(Event.start(operation: .moveShoppingItem, parameters: parameters))
        do {
            try await actionState.run { try await interactor.moveShoppingItem(item, to: listID) }
            interactor.trackEvent(Event.success(operation: .moveShoppingItem, parameters: parameters)); return true
        } catch { interactor.trackEvent(Event.fail(operation: .moveShoppingItem, error: error, parameters: parameters)); return false }
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

        let parameters = newTask.eventParameters
        interactor.trackEvent(Event.start(operation: .addChore, parameters: parameters))
        do {
            try await actionState.run { try await interactor.createTask(newTask) }
            interactor.trackEvent(Event.success(operation: .addChore, parameters: parameters)); return true
        } catch { interactor.trackEvent(Event.fail(operation: .addChore, error: error, parameters: parameters)); return false }
    }

    func toggleTaskStatus(_ task: TaskModel) async -> Bool {
        let parameters = task.eventParameters
        interactor.trackEvent(Event.start(operation: .toggleTaskStatus, parameters: parameters))
        do { try await actionState.run { try await interactor.toggleTaskStatus(task) }; interactor.trackEvent(Event.success(operation: .toggleTaskStatus, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .toggleTaskStatus, error: error, parameters: parameters)); return false }
    }

    func deleteTask(_ task: TaskModel) async -> Bool {
        let parameters = task.eventParameters
        interactor.trackEvent(Event.start(operation: .deleteTask, parameters: parameters))
        do { try await actionState.run { try await interactor.deleteTask(task) }; interactor.trackEvent(Event.success(operation: .deleteTask, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .deleteTask, error: error, parameters: parameters)); return false }
    }

    func fetchTasks() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        interactor.trackEvent(Event.start(operation: .fetchTasks, parameters: nil))
        do { try await actionState.run { try await interactor.fetchTasks(householdID: householdID, currentUserID: currentUser.id) }; interactor.trackEvent(Event.success(operation: .fetchTasks, parameters: nil)) }
        catch { interactor.trackEvent(Event.fail(operation: .fetchTasks, error: error, parameters: nil)) }
    }

    func loadMoreTasks() async {
        interactor.trackEvent(Event.start(operation: .loadMoreTasks, parameters: nil))
        do { try await actionState.run { try await interactor.loadMoreTasks() }; interactor.trackEvent(Event.success(operation: .loadMoreTasks, parameters: nil)) }
        catch { interactor.trackEvent(Event.fail(operation: .loadMoreTasks, error: error, parameters: nil)) }
    }

    func ensureTasksLoaded(for date: Date, minimumCount: Int) async {
        let calendar = Calendar.autoupdatingCurrent
        var previousTaskCount = -1

        while tasks.filter({ task in
            task.dueDate.map {
                calendar.isDate($0, inSameDayAs: date)
            } == true
        }).count < minimumCount,
        canLoadMoreTasks,
        tasks.count != previousTaskCount {
            previousTaskCount = tasks.count
            await loadMoreTasks()
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

        let parameters = newItem.eventParameters
        interactor.trackEvent(Event.start(operation: .addShoppingItem, parameters: parameters))
        do { try await actionState.run { try await interactor.createShoppingItem(newItem) }; interactor.trackEvent(Event.success(operation: .addShoppingItem, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .addShoppingItem, error: error, parameters: parameters)); return false }
    }

    func toggleShoppingItem(
        _ item: ShoppingItemModel
    ) async -> Bool {
        let parameters = item.eventParameters
        interactor.trackEvent(Event.start(operation: .toggleShoppingItem, parameters: parameters))
        do { try await actionState.run { try await interactor.toggleShoppingItemPurchased(item) }; interactor.trackEvent(Event.success(operation: .toggleShoppingItem, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .toggleShoppingItem, error: error, parameters: parameters)); return false }
    }

    func deleteShoppingItem(
        _ item: ShoppingItemModel
    ) async -> Bool {
        let parameters = item.eventParameters
        interactor.trackEvent(Event.start(operation: .deleteShoppingItem, parameters: parameters))
        do { try await actionState.run { try await interactor.deleteShoppingItem(item) }; interactor.trackEvent(Event.success(operation: .deleteShoppingItem, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .deleteShoppingItem, error: error, parameters: parameters)); return false }
    }

    func clearPurchasedShoppingItems(listID: String? = nil) async -> Bool {
        let parameters = listID.map { ["shopping_list_id": $0] }
        interactor.trackEvent(Event.start(operation: .clearPurchasedShoppingItems, parameters: parameters))
        do { try await actionState.run { try await interactor.clearPurchasedShoppingItems(listID: listID) }; interactor.trackEvent(Event.success(operation: .clearPurchasedShoppingItems, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .clearPurchasedShoppingItems, error: error, parameters: parameters)); return false }
    }

    func fetchShoppingItems() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        interactor.trackEvent(Event.start(operation: .fetchShoppingItems, parameters: nil))
        do { try await actionState.run { try await interactor.fetchShoppingItems(householdID: householdID) }; interactor.trackEvent(Event.success(operation: .fetchShoppingItems, parameters: nil)) }
        catch { interactor.trackEvent(Event.fail(operation: .fetchShoppingItems, error: error, parameters: nil)) }
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

        interactor.trackEvent(Event.addBillStart(bill: newBill))

        do {
            try await actionState.run {
                try await interactor.createBill(newBill)
            }
            interactor.trackEvent(Event.addBillSuccess(bill: newBill))
            return true
        } catch {
            interactor.trackEvent(
                Event.addBillFail(
                    error: error,
                    bill: newBill
                )
            )
            return false
        }
    }

    func markBillAsPaid(_ bill: BillModel) async -> Bool {
        let parameters = bill.eventParameters
        interactor.trackEvent(Event.start(operation: .markBillAsPaid, parameters: parameters))
        do { try await actionState.run { try await interactor.markBillAsPaid(bill, paidByUserID: currentUser.id) }; interactor.trackEvent(Event.success(operation: .markBillAsPaid, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .markBillAsPaid, error: error, parameters: parameters)); return false }
    }

    func deleteBill(_ bill: BillModel) async -> Bool {
        let parameters = bill.eventParameters
        interactor.trackEvent(Event.start(operation: .deleteBill, parameters: parameters))
        do { try await actionState.run { try await interactor.deleteBill(bill) }; interactor.trackEvent(Event.success(operation: .deleteBill, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .deleteBill, error: error, parameters: parameters)); return false }
    }

    func fetchBills() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        interactor.trackEvent(Event.start(operation: .fetchBills, parameters: nil))
        do { try await actionState.run { try await interactor.fetchBills(householdID: householdID) }; interactor.trackEvent(Event.success(operation: .fetchBills, parameters: nil)) }
        catch { interactor.trackEvent(Event.fail(operation: .fetchBills, error: error, parameters: nil)) }
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

        let parameters = poll.eventParameters
        interactor.trackEvent(Event.start(operation: .addPoll, parameters: parameters))
        do { try await actionState.run { try await interactor.createPoll(poll) }; interactor.trackEvent(Event.success(operation: .addPoll, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .addPoll, error: error, parameters: parameters)); return false }
    }

    func vote(in poll: PollModel, for option: PollOptionModel) async -> Bool {
        let parameters = poll.eventParameters.merging(option.eventParameters) { current, _ in current }
        interactor.trackEvent(Event.start(operation: .vote, parameters: parameters))
        do { try await actionState.run { try await interactor.vote(in: poll, option: option, userID: currentUser.id) }; interactor.trackEvent(Event.success(operation: .vote, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .vote, error: error, parameters: parameters)); return false }
    }

    func removeVote(in poll: PollModel) async -> Bool {
        let parameters = poll.eventParameters
        interactor.trackEvent(Event.start(operation: .removeVote, parameters: parameters))
        do { try await actionState.run { try await interactor.removeVote(in: poll, userID: currentUser.id) }; interactor.trackEvent(Event.success(operation: .removeVote, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .removeVote, error: error, parameters: parameters)); return false }
    }

    func closePoll(_ poll: PollModel) async -> Bool {
        let parameters = poll.eventParameters
        interactor.trackEvent(Event.start(operation: .closePoll, parameters: parameters))
        do { try await actionState.run { try await interactor.closePoll(poll, currentUserID: currentUser.id) }; interactor.trackEvent(Event.success(operation: .closePoll, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .closePoll, error: error, parameters: parameters)); return false }
    }

    func deletePoll(_ poll: PollModel) async -> Bool {
        let parameters = poll.eventParameters
        interactor.trackEvent(Event.start(operation: .deletePoll, parameters: parameters))
        do { try await actionState.run { try await interactor.deletePoll(poll, currentUserID: currentUser.id) }; interactor.trackEvent(Event.success(operation: .deletePoll, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .deletePoll, error: error, parameters: parameters)); return false }
    }

    func loadPollsIfNeeded() async {
        guard !didLoadPolls, let householdID = currentUser.householdId else { return }
        didLoadPolls = true
        interactor.trackEvent(Event.start(operation: .loadPolls, parameters: nil))
        do { try await actionState.run { try await interactor.fetchPolls(householdID: householdID) }; interactor.trackEvent(Event.success(operation: .loadPolls, parameters: nil)) }
        catch { didLoadPolls = false; interactor.trackEvent(Event.fail(operation: .loadPolls, error: error, parameters: nil)) }
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

        let parameters = reminder.eventParameters
        interactor.trackEvent(Event.start(operation: .addReminder, parameters: parameters))
        do { try await actionState.run { try await interactor.createHouseReminder(reminder) }; interactor.trackEvent(Event.success(operation: .addReminder, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .addReminder, error: error, parameters: parameters)); return false }
    }

    func deleteReminder(_ reminder: HouseReminderModel) async -> Bool {
        let parameters = reminder.eventParameters
        interactor.trackEvent(Event.start(operation: .deleteReminder, parameters: parameters))
        do { try await actionState.run { try await interactor.deleteHouseReminder(reminder, currentUserID: currentUser.id, ownerUserID: householdOwnerUserID) }; interactor.trackEvent(Event.success(operation: .deleteReminder, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .deleteReminder, error: error, parameters: parameters)); return false }
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

        let parameters = updatedReminder.eventParameters
        interactor.trackEvent(Event.start(operation: .updateReminder, parameters: parameters))
        do { try await actionState.run { try await interactor.updateHouseReminder(updatedReminder, currentUserID: currentUser.id, ownerUserID: householdOwnerUserID) }; interactor.trackEvent(Event.success(operation: .updateReminder, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .updateReminder, error: error, parameters: parameters)); return false }
    }

    // MARK: - Document Actions

    func loadDocumentsIfNeeded() async {
        guard !didLoadDocuments, let householdID = currentUser.householdId else { return }
        didLoadDocuments = true
        interactor.trackEvent(Event.start(operation: .loadDocuments, parameters: nil))
        do { try await actionState.run { try await interactor.fetchHouseholdDocuments(householdID: householdID) }; interactor.trackEvent(Event.success(operation: .loadDocuments, parameters: nil)) }
        catch { didLoadDocuments = false; interactor.trackEvent(Event.fail(operation: .loadDocuments, error: error, parameters: nil)) }
    }

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
        let parameters = document.eventParameters
        interactor.trackEvent(Event.start(operation: .addDocument, parameters: parameters))
        do { try await actionState.run { try await interactor.createHouseholdDocument(document, attachment: attachment) }; interactor.trackEvent(Event.success(operation: .addDocument, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .addDocument, error: error, parameters: parameters)); return false }
    }

    func deleteDocument(_ document: HouseholdDocumentModel) async -> Bool {
        guard document.createdByUserId == currentUser.id
                || currentUser.id == householdOwnerUserID else { return false }
        let parameters = document.eventParameters
        interactor.trackEvent(Event.start(operation: .deleteDocument, parameters: parameters))
        do { try await actionState.run { try await interactor.deleteHouseholdDocument(document) }; interactor.trackEvent(Event.success(operation: .deleteDocument, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .deleteDocument, error: error, parameters: parameters)); return false }
    }

    func updateDocument(_ document: HouseholdDocumentModel) async -> Bool {
        guard document.createdByUserId == currentUser.id
                || currentUser.id == householdOwnerUserID else { return false }
        let parameters = document.eventParameters
        interactor.trackEvent(Event.start(operation: .updateDocument, parameters: parameters))
        do { try await actionState.run { try await interactor.updateHouseholdDocument(document) }; interactor.trackEvent(Event.success(operation: .updateDocument, parameters: parameters)); return true }
        catch { interactor.trackEvent(Event.fail(operation: .updateDocument, error: error, parameters: parameters)); return false }
    }

    func refreshData() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        interactor.trackEvent(Event.start(operation: .refreshData, parameters: nil))
        do {
            try await actionState.run {
                try await interactor.fetchTasks(householdID: householdID, currentUserID: currentUser.id)
                try await interactor.fetchShoppingItems(householdID: householdID)
                try await interactor.fetchBills(householdID: householdID)
                try await interactor.fetchPolls(householdID: householdID)
                try await interactor.fetchHouseReminders(householdID: householdID)
                try await interactor.fetchHouseholdDocuments(householdID: householdID)
            }
            interactor.trackEvent(Event.success(operation: .refreshData, parameters: nil))
        } catch { interactor.trackEvent(Event.fail(operation: .refreshData, error: error, parameters: nil)) }
    }

    enum Event: LoggableEvent {
        case addBillStart(bill: BillModel)
        case addBillSuccess(bill: BillModel)
        case addBillFail(error: Error, bill: BillModel)

        case start(operation: Operation, parameters: [String: Any]?)
        case success(operation: Operation, parameters: [String: Any]?)
        case fail(operation: Operation, error: Error, parameters: [String: Any]?)

        enum Operation: String {
            case saveShoppingList = "SaveShoppingList"
            case moveShoppingItem = "MoveShoppingItem"
            case addChore = "AddChore"
            case toggleTaskStatus = "ToggleTaskStatus"
            case deleteTask = "DeleteTask"
            case fetchTasks = "FetchTasks"
            case loadMoreTasks = "LoadMoreTasks"
            case addShoppingItem = "AddShoppingItem"
            case toggleShoppingItem = "ToggleShoppingItem"
            case deleteShoppingItem = "DeleteShoppingItem"
            case clearPurchasedShoppingItems = "ClearPurchasedShoppingItems"
            case fetchShoppingItems = "FetchShoppingItems"
            case addBill = "AddBill"
            case markBillAsPaid = "MarkBillAsPaid"
            case deleteBill = "DeleteBill"
            case fetchBills = "FetchBills"
            case addPoll = "AddPoll"
            case vote = "Vote"
            case removeVote = "RemoveVote"
            case closePoll = "ClosePoll"
            case deletePoll = "DeletePoll"
            case loadPolls = "LoadPolls"
            case addReminder = "AddReminder"
            case deleteReminder = "DeleteReminder"
            case updateReminder = "UpdateReminder"
            case loadDocuments = "LoadDocuments"
            case addDocument = "AddDocument"
            case deleteDocument = "DeleteDocument"
            case updateDocument = "UpdateDocument"
            case refreshData = "RefreshData"
        }

        var eventName: String {
            switch self {
            case .addBillStart: "HouseholdView_AddBill_Start"
            case .addBillSuccess: "HouseholdView_AddBill_Success"
            case .addBillFail: "HouseholdView_AddBill_Fail"
            case .start(let operation, _): "HouseholdView_\(operation.rawValue)_Start"
            case .success(let operation, _): "HouseholdView_\(operation.rawValue)_Success"
            case .fail(let operation, _, _): "HouseholdView_\(operation.rawValue)_Fail"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .addBillStart(let bill), .addBillSuccess(let bill):
                bill.eventParameters
            case .addBillFail(let error, let bill):
                bill.eventParameters.merging(error.eventParameters) { current, _ in current }
            case .start(_, let parameters), .success(_, let parameters):
                parameters
            case .fail(_, let error, let parameters):
                (parameters ?? [:]).merging(error.eventParameters) { current, _ in current }
            }
        }

        var type: LogType {
            switch self {
            case .addBillFail, .fail:
                return .severe
            default:
                return .analytic
            }
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
        .screenAppearAnalytics(name: "HouseholdView")
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
        let action: () -> Void = switch feature {
        case .bills: onOpenBills
        case .cleaning: onOpenCleaning
        case .shopping: onOpenShopping
        case .polls: onOpenPolls
        case .reminders: onOpenReminders
        case .documents: onOpenDocuments
        }

        return {
            action()
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
