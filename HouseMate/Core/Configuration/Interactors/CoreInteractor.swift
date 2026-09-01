//
//  CoreInteractor.swift
//  HouseMate
//
//  Created by Marcin Turek on 26/08/2026.
//



import Foundation
import AuthenticationServices

@MainActor
struct CoreInteractor {

    private let authService:
        any AuthServiceProtocol

    private let userService:
        any UserServiceProtocol

    private let householdManager:
        HouseholdManager

    private let taskManager:
        TaskManager

    private let shoppingManager:
        ShoppingManager

    private let billManager:
        BillManager

    private let householdBoardManager:
        HouseholdBoardManager

    private let pollManager:
        PollManager

    private let houseReminderManager:
        HouseReminderManager

    private let notificationManager:
        NotificationManager

    private let localNotificationService:
        any LocalNotificationServiceProtocol

    init(
        container: DependencyContainer
    ) {
        self.authService = container.authService
        self.userService = container.userService
        self.householdManager = container.householdManager
        self.taskManager = container.taskManager
        self.shoppingManager = container.shoppingManager
        self.billManager = container.billManager
        self.householdBoardManager = container.householdBoardManager
        self.pollManager = container.pollManager
        self.houseReminderManager = container.houseReminderManager
        self.notificationManager = container.notificationManager
        self.localNotificationService = container.localNotificationService
    }

    // MARK: - Authentication

    var currentAuthUser: UserAuthInfo? {
        authService.currentUser
    }

    func authStateChanges()
        -> AsyncStream<UserAuthInfo?> {
        authService.authStateChanges()
    }

    func configureAppleRequest(
        _ request: ASAuthorizationAppleIDRequest
    ) {
        authService.configureAppleRequest(request)
    }

    func signInWithApple(
        _ result: Result<ASAuthorization, Error>
    ) async throws -> AuthSignInResult {
        try await authService.signInWithApple(result)
    }

    func signInWithGoogle() async throws
        -> AuthSignInResult {
        try await authService.signInWithGoogle()
    }

    func signOut() throws {
        try authService.signOut()
    }

    // MARK: - User

    func getUser(
        userID: String
    ) async throws -> UserModel? {
        try await userService.fetchUser(
            userID: userID
        )
    }

    func createUser(
        from authInfo: UserAuthInfo
    ) async throws -> UserModel {
        try await userService.createUser(
            from: authInfo
        )
    }

    func saveUser(
        _ user: UserModel
    ) async throws {
        try await userService.saveUser(user)
    }

    func updateHouseholdID(
        _ householdID: String?,
        userID: String
    ) async throws {
        try await userService.updateHouseholdID(
            householdID,
            for: userID
        )
    }

    // MARK: - HouseholdManager

    var currentHousehold: HouseholdModel? {
        householdManager.currentHousehold
    }

    var currentHouseholdMembers: [HouseholdMemberModel] {
        householdManager.currentMembers
    }

    func createHousehold(name: String, owner: UserModel) async throws -> HouseholdModel {
        try await householdManager.createHousehold(
            name: name,
            owner: owner
        )
    }

    func joinHousehold(inviteCode: String, user: UserModel) async throws -> HouseholdModel {
        try await householdManager.joinHousehold(
            inviteCode: inviteCode,
            user: user
        )
    }

    func fetchHousehold(householdID: String) async throws -> HouseholdModel? {
        try await householdManager.fetchHousehold(
            householdID: householdID
        )
    }

    func clearCurrentHousehold() {
        householdManager.clearCurrentHousehold()
    }

    // MARK: - Tasks

    var tasks: [TaskModel] {
        taskManager.tasks
    }

    func fetchTasks(householdID: String, currentUserID: String) async throws {
        try await taskManager.fetchTasks(householdID: householdID, currentUserID: currentUserID)
    }

    func createTask(_ task: TaskModel) async throws {
        try await taskManager.createTask(task)
    }

    func toggleTaskStatus(_ task: TaskModel) async throws {
        try await taskManager.toggleStatus(task)
    }

    func deleteTask(_ task: TaskModel) async throws {
        try await taskManager.deleteTask(task)
    }

    func clearTasks() {
        taskManager.clearTasks()
    }

    // MARK: - Shopping

    var shoppingItems: [ShoppingItemModel] {
        shoppingManager.items
    }

    func fetchShoppingItems(householdID: String) async throws {
        try await shoppingManager.fetchItems(householdID: householdID)
    }

    func createShoppingItem(_ item: ShoppingItemModel) async throws {
        try await shoppingManager.createItem(item)
    }

    func toggleShoppingItemPurchased(_ item: ShoppingItemModel) async throws {
        try await shoppingManager.togglePurchased(item)
    }

    func deleteShoppingItem(_ item: ShoppingItemModel) async throws {
        try await shoppingManager.deleteItem(item)
    }

    func clearPurchasedShoppingItems() async throws {
        try await shoppingManager.clearPurchasedItems()
    }

    func clearShoppingItems() {
        shoppingManager.clearItems()
    }

    // MARK: - Bills

    var bills: [BillModel] {
        billManager.bills
    }

    func fetchBills(householdID: String) async throws {
        try await billManager.fetchBills(householdID: householdID)
    }

    func createBill(_ bill: BillModel) async throws {
        try await billManager.createBill(bill)
    }

    func markBillAsPaid(_ bill: BillModel, paidByUserID: String) async throws {
        try await billManager.markAsPaid(bill, paidByUserID: paidByUserID)
    }

    func deleteBill(_ bill: BillModel) async throws {
        try await billManager.deleteBill(bill)
    }

    func clearBills() {
        billManager.clearBills()
    }

    // MARK: - Household Board

    var boardPosts: [BoardPostModel] {
        householdBoardManager.posts
    }

    var isLoadingMoreBoardPosts: Bool {
        householdBoardManager.isLoading
    }

    var canLoadMoreBoardPosts: Bool {
        householdBoardManager.canLoadMore
    }

    func fetchInitialBoardPosts(householdID: String) async throws {
        try await householdBoardManager.fetchInitialPosts(householdID: householdID)
    }

    func loadMoreBoardPosts() async throws {
        try await householdBoardManager.loadMorePosts()
    }

    func createBoardPost(_ post: BoardPostModel) async throws {
        try await householdBoardManager.createPost(post)
    }

    func deleteBoardPost(_ post: BoardPostModel, currentUserID: String) async throws {
        try await householdBoardManager.deletePost(post, currentUserID: currentUserID)
    }

    func clearBoardPosts() {
        householdBoardManager.clearPosts()
    }

    // MARK: - Polls

    var polls: [PollModel] {
        pollManager.polls
    }

    func fetchPolls(householdID: String) async throws {
        try await pollManager.fetchPolls(householdID: householdID)
    }

    func createPoll(_ poll: PollModel) async throws {
        try await pollManager.createPoll(poll)
    }

    func vote(in poll: PollModel, option: PollOptionModel, userID: String) async throws {
        try await pollManager.vote(in: poll, option: option, userID: userID)
    }

    func closePoll(_ poll: PollModel, currentUserID: String) async throws {
        try await pollManager.closePoll(poll, currentUserID: currentUserID)
    }

    func deletePoll(_ poll: PollModel, currentUserID: String) async throws {
        try await pollManager.deletePoll(poll, currentUserID: currentUserID)
    }

    func clearPolls() {
        pollManager.clearPolls()
    }

    // MARK: - House Reminders

    var houseReminders: [HouseReminderModel] {
        houseReminderManager.reminders
    }

    func fetchHouseReminders(householdID: String) async throws {
        try await houseReminderManager.fetchReminders(householdID: householdID)
    }

    func createHouseReminder(_ reminder: HouseReminderModel) async throws {
        try await houseReminderManager.createReminder(reminder)
    }

    func deleteHouseReminder(_ reminder: HouseReminderModel, currentUserID: String, ownerUserID: String) async throws {
        try await houseReminderManager.deleteReminder(
            reminder,
            currentUserID: currentUserID,
            ownerUserID: ownerUserID
        )
    }

    func clearHouseReminders() {
        houseReminderManager.clearReminders()
    }

    // MARK: - Notifications

    var notifications: [NotificationModel] {
        notificationManager.notifications
    }

    func fetchNotifications(userID: String) async throws {
        try await notificationManager.fetchNotifications(userID: userID)
    }

    func markNotificationAsRead(_ notification: NotificationModel, userID: String) async throws {
        try await notificationManager.markAsRead(notification, userID: userID)
    }

    func markAllNotificationsAsRead(userID: String) async throws {
        try await notificationManager.markAllAsRead(userID: userID)
    }

    func deleteNotification(_ notification: NotificationModel, userID: String) async throws {
        try await notificationManager.deleteNotification(notification, userID: userID)
    }

    func clearNotifications() {
        notificationManager.clearNotifications()
    }

    func applyLocalNotificationPreferences() async {
        await localNotificationService.applyPreferences()
        taskManager.refreshNotifications()
        billManager.refreshNotifications()
        houseReminderManager.refreshNotifications()
    }

    func localNotificationAuthorizationStatus() async -> LocalNotificationAuthorizationStatus {
        await localNotificationService.authorizationStatus()
    }

    func sendTestNotification() async throws {
        try await localNotificationService.scheduleTestNotification()
    }
}
