//
//  NotificationModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//



import Foundation

struct NotificationModel: Identifiable, Codable, Equatable {

    var id: String {
        notificationId
    }

    let notificationId: String
    let recipientUserId: String
    let householdId: String?

    let createdAt: Date?

    var type: NotificationType
    var title: String
    var message: String

    var isRead: Bool

    var relatedEntityId: String?
    var destination: NotificationDestination?

    init(
        notificationId: String,
        recipientUserId: String,
        householdId: String? = nil,
        createdAt: Date? = nil,
        type: NotificationType,
        title: String,
        message: String,
        isRead: Bool = false,
        relatedEntityId: String? = nil,
        destination: NotificationDestination? = nil
    ) {
        self.notificationId = notificationId
        self.recipientUserId = recipientUserId
        self.householdId = householdId
        self.createdAt = createdAt
        self.type = type
        self.title = title
        self.message = message
        self.isRead = isRead
        self.relatedEntityId = relatedEntityId
        self.destination = destination
    }

    enum CodingKeys: String, CodingKey {
        case notificationId = "notification_id"
        case recipientUserId = "recipient_user_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case type
        case title
        case message
        case isRead = "is_read"
        case relatedEntityId = "related_entity_id"
        case destination
    }

    var eventParameters: [String: Any] {
        let dictionary: [String: Any?] = [
            "notification_\(CodingKeys.notificationId.rawValue)":
                notificationId,
            "notification_\(CodingKeys.recipientUserId.rawValue)":
                recipientUserId,
            "notification_\(CodingKeys.householdId.rawValue)":
                householdId,
            "notification_\(CodingKeys.createdAt.rawValue)":
                createdAt,
            "notification_\(CodingKeys.type.rawValue)":
                type.rawValue,
            "notification_\(CodingKeys.title.rawValue)":
                title,
            "notification_\(CodingKeys.message.rawValue)":
                message,
            "notification_\(CodingKeys.isRead.rawValue)":
                isRead,
            "notification_\(CodingKeys.relatedEntityId.rawValue)":
                relatedEntityId,
            "notification_\(CodingKeys.destination.rawValue)":
                destination?.rawValue
        ]

        return dictionary.compactMapValues { $0 }
    }
}

// MARK: - Notification Type

enum NotificationType: String, Codable, CaseIterable {
    case taskAssigned
    case taskDue
    case billDue
    case newPoll
    case houseReminder
    case newBoardPost
    case householdInvitation

    var systemImage: String {
        switch self {
        case .taskAssigned:
            return "person.crop.circle.badge.checkmark"

        case .taskDue:
            return "checklist"

        case .billDue:
            return "creditcard.fill"

        case .newPoll:
            return "chart.bar.doc.horizontal"

        case .houseReminder:
            return "bell.badge.fill"

        case .newBoardPost:
            return "text.bubble.fill"

        case .householdInvitation:
            return "person.badge.plus"
        }
    }
}

// MARK: - Destination

enum NotificationDestination: String, Codable {
    case household
    case housemates
}

// MARK: - Mock Data

extension NotificationModel {

    static let mock = NotificationModel(
        notificationId: "notification_1",
        recipientUserId: "1",
        householdId: "house_123",
        createdAt: pastDate(minutes: 10),
        type: .taskDue,
        title: "Chore due today",
        message: "Clean bathroom is due at 10:00.",
        isRead: false,
        relatedEntityId: "task_3",
        destination: .household
    )

    static let mockList: [NotificationModel] = [
        NotificationModel(
            notificationId: "notification_1",
            recipientUserId: "1",
            householdId: "house_123",
            createdAt: pastDate(minutes: 10),
            type: .taskDue,
            title: "Chore due today",
            message: "Clean bathroom is due at 10:00.",
            isRead: false,
            relatedEntityId: "task_3",
            destination: .household
        ),

        NotificationModel(
            notificationId: "notification_2",
            recipientUserId: "1",
            householdId: "house_123",
            createdAt: pastDate(minutes: 35),
            type: .newPoll,
            title: "New household poll",
            message: "Adam asked: What should we order tonight?",
            isRead: false,
            relatedEntityId: "poll_1",
            destination: .housemates
        ),

        NotificationModel(
            notificationId: "notification_3",
            recipientUserId: "1",
            householdId: "house_123",
            createdAt: pastDate(hours: 2),
            type: .billDue,
            title: "Bill due tomorrow",
            message: "Electricity bill of £84.50 is due tomorrow.",
            isRead: false,
            relatedEntityId: "bill_1",
            destination: .household
        ),

        NotificationModel(
            notificationId: "notification_4",
            recipientUserId: "1",
            householdId: "house_123",
            createdAt: pastDate(hours: 5),
            type: .houseReminder,
            title: "Recycling collection",
            message: "Put the blue bin outside tomorrow.",
            isRead: true,
            relatedEntityId: "reminder_2",
            destination: .housemates
        ),

        NotificationModel(
            notificationId: "notification_5",
            recipientUserId: "1",
            householdId: "house_123",
            createdAt: pastDate(days: 1),
            type: .taskAssigned,
            title: "New chore assigned",
            message: "Adam assigned Do laundry to you.",
            isRead: true,
            relatedEntityId: "task_4",
            destination: .household
        ),

        NotificationModel(
            notificationId: "notification_6",
            recipientUserId: "1",
            householdId: "house_123",
            createdAt: pastDate(days: 2),
            type: .newBoardPost,
            title: "New board post",
            message: "Kamil shared a new message.",
            isRead: true,
            relatedEntityId: "post_2",
            destination: .housemates
        )
    ]

    private static func pastDate(
        minutes: Int
    ) -> Date {
        Calendar.autoupdatingCurrent.date(
            byAdding: .minute,
            value: -minutes,
            to: .now
        ) ?? .now
    }

    private static func pastDate(
        hours: Int
    ) -> Date {
        Calendar.autoupdatingCurrent.date(
            byAdding: .hour,
            value: -hours,
            to: .now
        ) ?? .now
    }

    private static func pastDate(
        days: Int
    ) -> Date {
        Calendar.autoupdatingCurrent.date(
            byAdding: .day,
            value: -days,
            to: .now
        ) ?? .now
    }
}
