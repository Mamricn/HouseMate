//
//  FirebaseNotificationService.swift
//  HouseMate
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseNotificationService: NotificationServiceProtocol {

    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func fetchNotifications(userID: String, limit: Int) async throws -> [NotificationModel] {
        let snapshot = try await notificationsCollection(userID: userID)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try decode(snapshot)
    }

    func observeNotifications(userID: String, limit: Int, onChange: @escaping (Result<[NotificationModel], Error>) -> Void) -> ServiceObservation? {
        let listener = notificationsCollection(userID: userID)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                do {
                    let notifications = try snapshot.map { try self.decode($0) } ?? []
                    onChange(.success(notifications))
                } catch {
                    onChange(.failure(error))
                }
            }

        return ServiceObservation(cancellation: listener.remove)
    }

    func markAsRead(notificationID: String, userID: String) async throws {
        try await notificationsCollection(userID: userID)
            .document(notificationID)
            .updateData(["is_read": true])
    }

    func markAllAsRead(_ notifications: [NotificationModel], userID: String) async throws {
        let unreadNotifications = notifications.filter { !$0.isRead }

        guard !unreadNotifications.isEmpty else {
            return
        }

        let batch = database.batch()

        for notification in unreadNotifications {
            let reference = notificationsCollection(userID: userID)
                .document(notification.notificationId)
            batch.updateData(["is_read": true], forDocument: reference)
        }

        try await batch.commit()
    }

    func deleteNotification(notificationID: String, userID: String) async throws {
        try await notificationsCollection(userID: userID)
            .document(notificationID)
            .delete()
    }

    private func notificationsCollection(userID: String) -> CollectionReference {
        database
            .collection("users")
            .document(userID)
            .collection("notifications")
    }

    private func decode(_ snapshot: QuerySnapshot) throws -> [NotificationModel] {
        try snapshot.documents.map {
            try Firestore.Decoder().decode(NotificationModel.self, from: $0.data())
        }
    }
}
