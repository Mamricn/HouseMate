//
//  MockLocalNotificationService.swift
//  HouseMate
//

import Foundation

@MainActor
final class MockLocalNotificationService: LocalNotificationServiceProtocol {

    func requestAuthorization() async throws -> Bool {
        true
    }

    func authorizationStatus() async -> LocalNotificationAuthorizationStatus {
        .enabled
    }

    func scheduleTestNotification() async throws {}

    func scheduleHouseReminder(_ reminder: HouseReminderModel) async throws {}

    func cancelHouseReminder(reminderID: String) {}

    func synchronizeHouseReminders(_ reminders: [HouseReminderModel]) async throws {}

    func scheduleTask(_ task: TaskModel, currentUserID: String) async throws {}

    func cancelTask(taskID: String) {}

    func synchronizeTasks(_ tasks: [TaskModel], currentUserID: String) async throws {}

    func scheduleBill(_ bill: BillModel) async throws {}

    func cancelBill(billID: String) {}

    func synchronizeBills(_ bills: [BillModel]) async throws {}

    func applyPreferences() async {}
}
