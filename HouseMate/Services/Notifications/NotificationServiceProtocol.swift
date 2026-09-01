//
//  NotificationServiceProtocol.swift
//  HouseMate
//

import Foundation

@MainActor
protocol NotificationServiceProtocol: AnyObject {

    func fetchNotifications(userID: String, limit: Int) async throws -> [NotificationModel]

    func observeNotifications(userID: String, limit: Int, onChange: @escaping (Result<[NotificationModel], Error>) -> Void) -> ServiceObservation?

    func markAsRead(notificationID: String, userID: String) async throws

    func markAllAsRead(_ notifications: [NotificationModel], userID: String) async throws

    func deleteNotification(notificationID: String, userID: String) async throws
}

extension NotificationServiceProtocol {

    func observeNotifications(userID: String, limit: Int, onChange: @escaping (Result<[NotificationModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }
}
