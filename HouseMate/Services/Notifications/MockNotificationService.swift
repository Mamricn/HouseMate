//
//  MockNotificationService.swift
//  HouseMate
//

import Foundation

@MainActor
final class MockNotificationService: NotificationServiceProtocol {

    private var notifications: [NotificationModel]

    init(notifications: [NotificationModel]) {
        self.notifications = notifications
    }

    convenience init() {
        self.init(notifications: NotificationModel.mockList)
    }

    func fetchNotifications(userID: String, limit: Int) async throws -> [NotificationModel] {
        Array(
            notifications
                .filter { $0.recipientUserId == userID }
                .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
                .prefix(limit)
        )
    }

    func markAsRead(notificationID: String, userID: String) async throws {
        guard let index = notifications.firstIndex(where: {
            $0.notificationId == notificationID && $0.recipientUserId == userID
        }) else {
            return
        }

        notifications[index].isRead = true
    }

    func markAllAsRead(_ notifications: [NotificationModel], userID: String) async throws {
        for index in self.notifications.indices where self.notifications[index].recipientUserId == userID {
            self.notifications[index].isRead = true
        }
    }

    func deleteNotification(notificationID: String, userID: String) async throws {
        notifications.removeAll {
            $0.notificationId == notificationID && $0.recipientUserId == userID
        }
    }
}
