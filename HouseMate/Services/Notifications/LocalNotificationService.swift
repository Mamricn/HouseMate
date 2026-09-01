//
//  LocalNotificationService.swift
//  HouseMate
//

import Foundation
import UserNotifications

@MainActor
final class LocalNotificationService: LocalNotificationServiceProtocol {

    private let notificationCenter: UNUserNotificationCenter
    private let houseReminderPrefix = "house-reminder-"
    private let taskPrefix = "task-reminder-"
    private let billPrefix = "bill-reminder-"

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func requestAuthorization() async throws -> Bool {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true

        case .denied:
            return false

        case .notDetermined:
            return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])

        @unknown default:
            return false
        }
    }

    func authorizationStatus() async -> LocalNotificationAuthorizationStatus {
        let status = await notificationCenter.notificationSettings().authorizationStatus

        switch status {
        case .authorized, .provisional, .ephemeral:
            return .enabled
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    func scheduleTestNotification() async throws {
        guard try await requestAuthorization() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "HouseMate notifications are ready"
        content.body = "You’ll receive reminders about chores, bills and household events."
        content.sound = .default
        content.userInfo = [
            "destination": NotificationDestination.household.rawValue,
            "type": NotificationType.houseReminder.rawValue
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "notification-test", content: content, trigger: trigger)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["notification-test"])
        try await notificationCenter.add(request)
    }

    func scheduleHouseReminder(_ reminder: HouseReminderModel) async throws {
        let identifier = notificationIdentifier(reminderID: reminder.reminderId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard reminder.reminderAdvance != .none,
              preferenceEnabled(key: "houseReminderNotificationsEnabled"),
              await isAuthorized,
              let notificationDate = nextNotificationDate(for: reminder) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.details ?? notificationBody(for: reminder)
        content.sound = .default
        content.userInfo = [
            "type": NotificationType.houseReminder.rawValue,
            "household_id": reminder.householdId,
            "reminder_id": reminder.reminderId,
            "destination": NotificationDestination.housemates.rawValue
        ]

        let dateComponents = Calendar.autoupdatingCurrent.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    func cancelHouseReminder(reminderID: String) {
        let identifier = notificationIdentifier(reminderID: reminderID)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    func synchronizeHouseReminders(_ reminders: [HouseReminderModel]) async throws {
        guard await isAuthorized else {
            return
        }

        let activeIdentifiers = Set(reminders.map { notificationIdentifier(reminderID: $0.reminderId) })
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let staleIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(houseReminderPrefix) && !activeIdentifiers.contains($0) }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)

        for reminder in reminders {
            try await scheduleHouseReminder(reminder)
        }
    }

    func scheduleTask(_ task: TaskModel, currentUserID: String) async throws {
        let identifier = "\(taskPrefix)\(task.taskId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard preferenceEnabled(key: "taskNotificationsEnabled"),
              task.assignedToUserId == currentUserID,
              task.status == .pending,
              let advance = task.notificationAdvance,
              advance != .none,
              let dueDate = task.dueDate,
              await isAuthorized,
              let notificationDate = notificationDate(for: dueDate, advance: advance, useNineAM: task.isAllDay) else {
            return
        }

        try await addNotification(
            identifier: identifier,
            title: task.title,
            body: task.description ?? "Your chore is due soon.",
            date: notificationDate,
            userInfo: [
                "type": NotificationType.taskDue.rawValue,
                "household_id": task.householdId,
                "task_id": task.taskId,
                "destination": NotificationDestination.household.rawValue
            ]
        )
    }

    func cancelTask(taskID: String) {
        cancel(identifier: "\(taskPrefix)\(taskID)")
    }

    func synchronizeTasks(_ tasks: [TaskModel], currentUserID: String) async throws {
        let relevantTasks = tasks.filter {
            $0.assignedToUserId == currentUserID && $0.status == .pending && $0.notificationAdvance != nil
        }
        try await synchronize(prefix: taskPrefix, identifiers: relevantTasks.map { "\(taskPrefix)\($0.taskId)" })

        for task in relevantTasks {
            try await scheduleTask(task, currentUserID: currentUserID)
        }
    }

    func scheduleBill(_ bill: BillModel) async throws {
        let identifier = "\(billPrefix)\(bill.billId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard preferenceEnabled(key: "billNotificationsEnabled"),
              bill.status != .paid,
              let advance = bill.notificationAdvance,
              advance != .none,
              let dueDate = bill.dueDate,
              await isAuthorized,
              let notificationDate = notificationDate(for: dueDate, advance: advance, useNineAM: true) else {
            return
        }

        try await addNotification(
            identifier: identifier,
            title: bill.title,
            body: "A bill of £\(String(format: "%.2f", bill.amount)) is due soon.",
            date: notificationDate,
            userInfo: [
                "type": NotificationType.billDue.rawValue,
                "household_id": bill.householdId,
                "bill_id": bill.billId,
                "destination": NotificationDestination.household.rawValue
            ]
        )
    }

    func cancelBill(billID: String) {
        cancel(identifier: "\(billPrefix)\(billID)")
    }

    func synchronizeBills(_ bills: [BillModel]) async throws {
        let relevantBills = bills.filter { $0.status != .paid && $0.notificationAdvance != nil }
        try await synchronize(prefix: billPrefix, identifiers: relevantBills.map { "\(billPrefix)\($0.billId)" })

        for bill in relevantBills {
            try await scheduleBill(bill)
        }
    }

    func applyPreferences() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        var identifiers: [String] = []

        if !preferenceEnabled(key: "taskNotificationsEnabled") {
            identifiers += pendingRequests.map(\.identifier).filter { $0.hasPrefix(taskPrefix) }
        }
        if !preferenceEnabled(key: "billNotificationsEnabled") {
            identifiers += pendingRequests.map(\.identifier).filter { $0.hasPrefix(billPrefix) }
        }
        if !preferenceEnabled(key: "houseReminderNotificationsEnabled") {
            identifiers += pendingRequests.map(\.identifier).filter { $0.hasPrefix(houseReminderPrefix) }
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private var isAuthorized: Bool {
        get async {
            let status = await notificationCenter.notificationSettings().authorizationStatus
            return status == .authorized || status == .provisional || status == .ephemeral
        }
    }

    private func nextNotificationDate(for reminder: HouseReminderModel) -> Date? {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date.now
        var occurrence = reminder.nextOccurrence(after: now, calendar: calendar)
        var iterations = 0

        while let currentOccurrence = occurrence, iterations < 100 {
            let occurrenceAtNineAM = calendar.date(
                bySettingHour: 9,
                minute: 0,
                second: 0,
                of: currentOccurrence
            ) ?? currentOccurrence

            guard let notificationDate = calendar.date(
                byAdding: .day,
                value: -reminder.reminderAdvance.daysBefore,
                to: occurrenceAtNineAM
            ) else {
                return nil
            }

            if notificationDate > now {
                return notificationDate
            }

            guard reminder.recurrence != .never else {
                return nil
            }

            occurrence = calendar.date(byAdding: reminder.recurrence.dateComponents, to: currentOccurrence)
            iterations += 1
        }

        return nil
    }

    private func notificationIdentifier(reminderID: String) -> String {
        "\(houseReminderPrefix)\(reminderID)"
    }

    private func notificationBody(for reminder: HouseReminderModel) -> String {
        switch reminder.reminderAdvance {
        case .none:
            return reminder.title
        case .sameDay:
            return "Scheduled for today."
        case .oneDayBefore:
            return "Scheduled for tomorrow."
        case .twoDaysBefore:
            return "Scheduled in 2 days."
        case .oneWeekBefore:
            return "Scheduled in 1 week."
        }
    }

    private func notificationDate(for date: Date, advance: HouseReminderAdvance, useNineAM: Bool) -> Date? {
        let calendar = Calendar.autoupdatingCurrent
        let eventDate = useNineAM
            ? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
            : date
        guard let result = calendar.date(byAdding: .day, value: -advance.daysBefore, to: eventDate), result > .now else {
            return nil
        }
        return result
    }

    private func addNotification(identifier: String, title: String, body: String, date: Date, userInfo: [AnyHashable: Any]) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        let components = Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await notificationCenter.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private func synchronize(prefix: String, identifiers: [String]) async throws {
        guard await isAuthorized else { return }
        let activeIdentifiers = Set(identifiers)
        let stale = await notificationCenter.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) && !activeIdentifiers.contains($0) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: stale)
    }

    private func cancel(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    private func preferenceEnabled(key: String) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key)
    }
}

private extension HouseReminderAdvance {

    var daysBefore: Int {
        switch self {
        case .none, .sameDay:
            return 0
        case .oneDayBefore:
            return 1
        case .twoDaysBefore:
            return 2
        case .oneWeekBefore:
            return 7
        }
    }
}
