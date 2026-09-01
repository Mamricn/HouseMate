//
//  NotificationManager.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class NotificationManager {

    private let service: any NotificationServiceProtocol
    private var observation: ServiceObservation?

    private(set) var notifications: [NotificationModel] = []

    init(service: any NotificationServiceProtocol) {
        self.service = service
    }

    func fetchNotifications(userID: String) async throws {
        observation?.cancel()
        observation = service.observeNotifications(userID: userID, limit: 50) { [weak self] result in
            if case .success(let notifications) = result {
                self?.notifications = notifications
            }
        }

        if observation == nil {
            notifications = try await service.fetchNotifications(userID: userID, limit: 50)
        }
    }

    func markAsRead(_ notification: NotificationModel, userID: String) async throws {
        guard notification.recipientUserId == userID, !notification.isRead else {
            return
        }

        try await service.markAsRead(notificationID: notification.notificationId, userID: userID)

        if let index = notifications.firstIndex(where: { $0.notificationId == notification.notificationId }) {
            notifications[index].isRead = true
        }
    }

    func markAllAsRead(userID: String) async throws {
        let userNotifications = notifications.filter { $0.recipientUserId == userID }
        try await service.markAllAsRead(userNotifications, userID: userID)

        for index in notifications.indices where notifications[index].recipientUserId == userID {
            notifications[index].isRead = true
        }
    }

    func deleteNotification(_ notification: NotificationModel, userID: String) async throws {
        guard notification.recipientUserId == userID else {
            return
        }

        try await service.deleteNotification(notificationID: notification.notificationId, userID: userID)
        notifications.removeAll { $0.notificationId == notification.notificationId }
    }

    func clearNotifications() {
        observation?.cancel()
        observation = nil
        notifications = []
    }
}
