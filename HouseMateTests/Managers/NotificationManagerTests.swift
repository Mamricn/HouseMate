import Foundation
import Testing
@testable import HouseMate

@Suite("NotificationManager — recipient protection and read state")
struct NotificationManagerTests {

    @Test("Mark all as read changes only the selected user's notifications")
    @MainActor
    func marksOnlySelectedUsersNotificationsAsRead() async throws {
        let first = makeNotification(id: "first", recipient: "user")
        let second = makeNotification(id: "second", recipient: "other")
        let manager = NotificationManager(
            service: MockNotificationService(notifications: [first, second])
        )

        // The manager normally fetches one user's feed. This service verifies
        // that only notifications belonging to that user enter the list.
        try await manager.fetchNotifications(userID: "user")
        #expect(manager.notifications == [first])

        try await manager.markAllAsRead(userID: "user")
        #expect(manager.notifications.allSatisfy { $0.isRead })
    }

    @Test("A user cannot delete a notification addressed to somebody else")
    @MainActor
    func preventsDeletingAnotherUsersNotification() async throws {
        let notification = makeNotification(id: "private", recipient: "owner")
        let manager = NotificationManager(
            service: MockNotificationService(notifications: [notification])
        )
        try await manager.fetchNotifications(userID: "owner")

        try await manager.deleteNotification(notification, userID: "other")
        #expect(manager.notifications == [notification])

        try await manager.deleteNotification(notification, userID: "owner")
        #expect(manager.notifications.isEmpty)
    }
}

private func makeNotification(id: String, recipient: String) -> NotificationModel {
    NotificationModel(
        notificationId: id,
        recipientUserId: recipient,
        householdId: "house-notifications",
        createdAt: .now,
        type: .taskAssigned,
        title: "New task",
        message: "A task was assigned to you"
    )
}
