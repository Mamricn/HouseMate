//
//  HouseReminderModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//

import Foundation

struct HouseReminderModel: Identifiable, Codable, Equatable {

    var id: String {
        reminderId
    }

    let reminderId: String
    let householdId: String
    let createdAt: Date?
    let createdByUserId: String

    var title: String
    var details: String?

    var firstOccurrenceDate: Date
    var recurrence: HouseReminderRecurrence
    var category: HouseReminderCategory
    var reminderAdvance: HouseReminderAdvance

    init(
        reminderId: String,
        householdId: String,
        createdAt: Date? = nil,
        createdByUserId: String,
        title: String,
        details: String? = nil,
        firstOccurrenceDate: Date,
        recurrence: HouseReminderRecurrence = .never,
        category: HouseReminderCategory = .other,
        reminderAdvance: HouseReminderAdvance = .none
    ) {
        self.reminderId = reminderId
        self.householdId = householdId
        self.createdAt = createdAt
        self.createdByUserId = createdByUserId
        self.title = title
        self.details = details
        self.firstOccurrenceDate = firstOccurrenceDate
        self.recurrence = recurrence
        self.category = category
        self.reminderAdvance = reminderAdvance
    }

    enum CodingKeys: String, CodingKey {
        case reminderId = "reminder_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case createdByUserId = "created_by_user_id"
        case title
        case details
        case firstOccurrenceDate = "first_occurrence_date"
        case recurrence
        case category
        case reminderAdvance = "reminder_advance"
    }

    func nextOccurrence(
        after referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        if firstOccurrenceDate >= referenceDate {
            return firstOccurrenceDate
        }

        guard recurrence != .never else {
            return nil
        }

        var candidate = firstOccurrenceDate
        var iterations = 0

        while candidate < referenceDate && iterations < 1_000 {
            guard let nextDate = calendar.date(
                byAdding: recurrence.dateComponents,
                to: candidate
            ) else {
                return nil
            }

            candidate = nextDate
            iterations += 1
        }

        return candidate
    }

    func nextNotificationDate(
        after referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        guard reminderAdvance != .none else {
            return nil
        }

        var occurrence = nextOccurrence(
            after: referenceDate,
            calendar: calendar
        )
        var iterations = 0

        while let currentOccurrence = occurrence,
              iterations < 100 {
            let occurrenceAtNineAM = calendar.date(
                bySettingHour: 9,
                minute: 0,
                second: 0,
                of: currentOccurrence
            ) ?? currentOccurrence
            let notificationDate = calendar.date(
                byAdding: .day,
                value: -reminderAdvance.daysBefore,
                to: occurrenceAtNineAM
            )

            if let notificationDate,
               notificationDate > referenceDate {
                return notificationDate
            }

            guard recurrence != .never else {
                return nil
            }

            occurrence = calendar.date(
                byAdding: recurrence.dateComponents,
                to: currentOccurrence
            )
            iterations += 1
        }

        return nil
    }

    var eventParameters: [String: Any] {
        let dictionary: [String: Any?] = [
            "reminder_\(CodingKeys.reminderId.rawValue)": reminderId,
            "reminder_\(CodingKeys.householdId.rawValue)": householdId,
            "reminder_\(CodingKeys.createdAt.rawValue)": createdAt,
            "reminder_\(CodingKeys.createdByUserId.rawValue)": createdByUserId,
            "reminder_\(CodingKeys.title.rawValue)": title,
            "reminder_\(CodingKeys.details.rawValue)": details,
            "reminder_\(CodingKeys.firstOccurrenceDate.rawValue)":
                firstOccurrenceDate,
            "reminder_\(CodingKeys.recurrence.rawValue)":
                recurrence.rawValue,
            "reminder_\(CodingKeys.category.rawValue)":
                category.rawValue,
            "reminder_\(CodingKeys.reminderAdvance.rawValue)":
                reminderAdvance.rawValue
        ]

        return dictionary.compactMapValues { $0 }
    }
}

// MARK: - Recurrence

enum HouseReminderRecurrence: String, Codable, CaseIterable {
    case never
    case weekly
    case biweekly
    case monthly
    case quarterly
    case yearly

    var title: String {
        switch self {
        case .never:
            return "Never"

        case .weekly:
            return "Every week"

        case .biweekly:
            return "Every 2 weeks"

        case .monthly:
            return "Every month"

        case .quarterly:
            return "Every 3 months"

        case .yearly:
            return "Every year"
        }
    }

    var dateComponents: DateComponents {
        switch self {
        case .never:
            return DateComponents()

        case .weekly:
            return DateComponents(day: 7)

        case .biweekly:
            return DateComponents(day: 14)

        case .monthly:
            return DateComponents(month: 1)

        case .quarterly:
            return DateComponents(month: 3)

        case .yearly:
            return DateComponents(year: 1)
        }
    }
}

// MARK: - Category

enum HouseReminderCategory: String, Codable, CaseIterable {
    case generalWaste
    case recycling
    case maintenance
    case inspection
    case meterReading
    case delivery
    case other

    var title: String {
        switch self {
        case .generalWaste:
            return "General Waste"

        case .recycling:
            return "Recycling"

        case .maintenance:
            return "Maintenance"

        case .inspection:
            return "Inspection"

        case .meterReading:
            return "Meter Reading"

        case .delivery:
            return "Delivery"

        case .other:
            return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .generalWaste:
            return "trash.fill"

        case .recycling:
            return "arrow.3.trianglepath"

        case .maintenance:
            return "wrench.and.screwdriver.fill"

        case .inspection:
            return "doc.text.magnifyingglass"

        case .meterReading:
            return "gauge.with.dots.needle.50percent"

        case .delivery:
            return "shippingbox.fill"

        case .other:
            return "house.fill"
        }
    }
}

// MARK: - Reminder Advance

enum HouseReminderAdvance: String, Codable, CaseIterable {
    case none
    case sameDay
    case oneDayBefore
    case twoDaysBefore
    case oneWeekBefore

    var title: String {
        switch self {
        case .none:
            return "None"

        case .sameDay:
            return "On the day"

        case .oneDayBefore:
            return "1 day before"

        case .twoDaysBefore:
            return "2 days before"

        case .oneWeekBefore:
            return "1 week before"
        }
    }

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

    func notificationDate(
        for dueDate: Date,
        useNineAM: Bool,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        guard self != .none else {
            return nil
        }

        let eventDate = useNineAM
            ? calendar.date(
                bySettingHour: 9,
                minute: 0,
                second: 0,
                of: dueDate
            ) ?? dueDate
            : dueDate

        guard let result = calendar.date(
            byAdding: .day,
            value: -daysBefore,
            to: eventDate
        ), result > now else {
            return nil
        }

        return result
    }
}

// MARK: - Mock Data

extension HouseReminderModel {

    static let mock = HouseReminderModel(
        reminderId: "reminder_1",
        householdId: "house_123",
        createdAt: .now,
        createdByUserId: "1",
        title: "General waste collection",
        details: "Put the black bin outside",
        firstOccurrenceDate: futureDate(daysFromNow: 1),
        recurrence: .weekly,
        category: .generalWaste,
        reminderAdvance: .oneDayBefore
    )

    static let mockList: [HouseReminderModel] = [
        HouseReminderModel(
            reminderId: "reminder_1",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "1",
            title: "General waste collection",
            details: "Put the black bin outside",
            firstOccurrenceDate: futureDate(daysFromNow: 1),
            recurrence: .weekly,
            category: .generalWaste,
            reminderAdvance: .oneDayBefore
        ),

        HouseReminderModel(
            reminderId: "reminder_2",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "2",
            title: "Recycling collection",
            details: "Put the blue bin outside",
            firstOccurrenceDate: futureDate(daysFromNow: 4),
            recurrence: .biweekly,
            category: .recycling,
            reminderAdvance: .oneDayBefore
        ),

        HouseReminderModel(
            reminderId: "reminder_3",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "1",
            title: "Electricity meter reading",
            firstOccurrenceDate: futureDate(daysFromNow: 7),
            recurrence: .monthly,
            category: .meterReading,
            reminderAdvance: .twoDaysBefore
        ),

        HouseReminderModel(
            reminderId: "reminder_4",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "3",
            title: "Boiler inspection",
            details: "Annual safety inspection",
            firstOccurrenceDate: futureDate(daysFromNow: 30),
            recurrence: .yearly,
            category: .inspection,
            reminderAdvance: .oneWeekBefore
        )
    ]

    private static func futureDate(
        daysFromNow: Int
    ) -> Date {
        Calendar.autoupdatingCurrent.date(
            byAdding: .day,
            value: daysFromNow,
            to: .now
        ) ?? .now
    }
}
