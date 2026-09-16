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

    private let householdDocumentManager:
        HouseholdDocumentManager

    private let notificationManager:
        NotificationManager

    private let localNotificationService:
        any LocalNotificationServiceProtocol

    private let remoteNotificationService:
        any RemoteNotificationServiceProtocol

    private let profileImageService:
        any ProfileImageServiceProtocol

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
        self.householdDocumentManager = container.householdDocumentManager
        self.notificationManager = container.notificationManager
        self.localNotificationService = container.localNotificationService
        self.remoteNotificationService = container.remoteNotificationService
        self.profileImageService = container.profileImageService
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

    func registerRemoteNotifications(for user: UserModel) async throws {
        let isAuthorized = try await localNotificationService
            .requestAuthorization()

        #if DEBUG
        print("Notification permission granted: \(isAuthorized)")
        #endif

        guard isAuthorized else {
            return
        }

        try await remoteNotificationService.registerDevice(for: user)
    }

    func unregisterRemoteNotifications(userID: String) async {
        await remoteNotificationService.unregisterCurrentDevice(
            userID: userID
        )
    }

    var currentAuthProvider: AuthProvider {
        authService.currentUser?.provider ?? .unknown
    }

    func reauthenticateWithApple(
        _ result: Result<ASAuthorization, Error>
    ) async throws {
        try await authService.reauthenticateWithApple(result)
    }

    func reauthenticateWithGoogle() async throws {
        try await authService.reauthenticateWithGoogle()
    }

    func deleteCurrentAuthUser() async throws {
        try await authService.deleteCurrentUser()
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

    func deleteUserData(userID: String) async throws {
        try await userService.deleteUserData(userID: userID)
    }

    func uploadProfileImage(
        data: Data,
        for user: UserModel
    ) async throws -> String {
        let compressedData = try ProfileImageProcessor.compressedJPEG(
            from: data
        )
        let newURL = try await profileImageService.uploadProfileImage(
            compressedData,
            userID: user.id
        )

        do {
            try await userService.updateProfileImageURL(
                newURL.absoluteString,
                userID: user.id,
                householdID: user.householdId
            )
        } catch {
            try? await profileImageService.deleteProfileImage(at: newURL)
            throw error
        }

        if let oldURLString = user.profileImageUrl,
           let oldURL = URL(string: oldURLString),
           oldURL != newURL {
            ProfileImageCache.shared.removeImage(for: oldURL)
            try? await profileImageService.deleteProfileImage(at: oldURL)
        }

        return newURL.absoluteString
    }

    func removeProfileImage(for user: UserModel) async throws {
        try await userService.updateProfileImageURL(
            nil,
            userID: user.id,
            householdID: user.householdId
        )

        if let urlString = user.profileImageUrl,
           let url = URL(string: urlString) {
            ProfileImageCache.shared.removeImage(for: url)
            try? await profileImageService.deleteProfileImage(at: url)
        }
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

    func updateAutomaticWeeklyAssignment(
        isEnabled: Bool,
        requestedByUserID: String
    ) async throws {
        try await householdManager.updateAutomaticWeeklyAssignment(
            isEnabled: isEnabled,
            requestedByUserID: requestedByUserID
        )
    }

    func runWeeklyAssignmentNow(requestedByUserID: String) async throws {
        try await householdManager.runWeeklyAssignmentNow(
            requestedByUserID: requestedByUserID
        )
    }

    func removeHouseholdMember(
        userID: String,
        requestedByUserID: String
    ) async throws {
        try await householdManager.removeMember(
            userID: userID,
            requestedByUserID: requestedByUserID
        )
    }

    func transferHouseholdOwnership(
        to newOwnerUserID: String,
        requestedByUserID: String
    ) async throws {
        try await householdManager.transferOwnership(
            to: newOwnerUserID,
            requestedByUserID: requestedByUserID
        )
    }

    func leaveHousehold(userID: String) async throws {
        try await householdManager.leaveHousehold(
            userID: userID
        )
    }

    func deleteHousehold(
        requestedByUserID: String
    ) async throws {
        try await householdManager.deleteHousehold(
            requestedByUserID: requestedByUserID
        )
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
    var shoppingLists: [ShoppingCollection] { shoppingManager.lists }
    func saveShoppingList(_ list: ShoppingCollection, householdID: String) async throws {
        try await shoppingManager.saveList(list, householdID: householdID)
    }
    func moveShoppingItem(_ item: ShoppingItemModel, to listID: String) async throws {
        try await shoppingManager.moveItem(item, to: listID)
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

    func clearPurchasedShoppingItems(listID: String? = nil) async throws {
        try await shoppingManager.clearPurchasedItems(listID: listID)
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

    func removeVote(in poll: PollModel, userID: String) async throws {
        try await pollManager.removeVote(in: poll, userID: userID)
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

    func updateHouseReminder(
        _ reminder: HouseReminderModel,
        currentUserID: String,
        ownerUserID: String
    ) async throws {
        try await houseReminderManager.updateReminder(
            reminder,
            currentUserID: currentUserID,
            ownerUserID: ownerUserID
        )
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

    // MARK: - Documents

    var householdDocuments: [HouseholdDocumentModel] {
        householdDocumentManager.documents
    }

    func fetchHouseholdDocuments(householdID: String) async throws {
        try await householdDocumentManager.fetchDocuments(householdID: householdID)
    }

    func createHouseholdDocument(
        _ document: HouseholdDocumentModel,
        attachment: DocumentAttachmentDraft
    ) async throws {
        try await householdDocumentManager.createDocument(document, attachment: attachment)
    }

    func updateHouseholdDocument(_ document: HouseholdDocumentModel) async throws {
        try await householdDocumentManager.updateDocument(document)
    }

    func deleteHouseholdDocument(_ document: HouseholdDocumentModel) async throws {
        try await householdDocumentManager.deleteDocument(document)
    }

    func clearHouseholdDocuments() {
        householdDocumentManager.clearDocuments()
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

        do {
            try await remoteNotificationService.updatePreferences()
        } catch {
            #if DEBUG
            print(
                "Remote notification preferences update failed: "
                + error.localizedDescription
            )
            #endif
        }
    }

    func localNotificationAuthorizationStatus() async -> LocalNotificationAuthorizationStatus {
        await localNotificationService.authorizationStatus()
    }

    func sendTestNotification() async throws {
        try await localNotificationService.scheduleTestNotification()
    }
}
