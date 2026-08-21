//
//  TaskModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import Foundation

struct TaskModel: Identifiable, Codable, Equatable {

    var id: String {
        taskId
    }

    let taskId: String
    let householdId: String
    let createdAt: Date?

    var title: String
    var description: String?

    var assignedToUserId: String?
    var createdByUserId: String

    var dueDate: Date?
    var isAllDay: Bool

    var status: TaskStatus
    var category: TaskCategory

    init(
        taskId: String,
        householdId: String,
        createdAt: Date? = nil,
        title: String,
        description: String? = nil,
        assignedToUserId: String? = nil,
        createdByUserId: String,
        dueDate: Date? = nil,
        isAllDay: Bool = false,
        status: TaskStatus = .pending,
        category: TaskCategory = .other
    ) {
        self.taskId = taskId
        self.householdId = householdId
        self.createdAt = createdAt
        self.title = title
        self.description = description
        self.assignedToUserId = assignedToUserId
        self.createdByUserId = createdByUserId
        self.dueDate = dueDate
        self.isAllDay = isAllDay
        self.status = status
        self.category = category
    }

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case title
        case description
        case assignedToUserId = "assigned_to_user_id"
        case createdByUserId = "created_by_user_id"
        case dueDate = "due_date"
        case isAllDay = "is_all_day"
        case status
        case category
    }

    var eventParameters: [String: Any] {
        let dictionary: [String: Any?] = [
            "task_\(CodingKeys.taskId.rawValue)": taskId,
            "task_\(CodingKeys.householdId.rawValue)": householdId,
            "task_\(CodingKeys.createdAt.rawValue)": createdAt,
            "task_\(CodingKeys.title.rawValue)": title,
            "task_\(CodingKeys.description.rawValue)": description,
            "task_\(CodingKeys.assignedToUserId.rawValue)": assignedToUserId,
            "task_\(CodingKeys.createdByUserId.rawValue)": createdByUserId,
            "task_\(CodingKeys.dueDate.rawValue)": dueDate,
            "task_\(CodingKeys.isAllDay.rawValue)": isAllDay,
            "task_\(CodingKeys.status.rawValue)": status.rawValue,
            "task_\(CodingKeys.category.rawValue)": category.rawValue
        ]

        return dictionary.compactMapValues { $0 }
    }
}

// MARK: - Task Status

enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case completed
}

// MARK: - Task Category

enum TaskCategory: String, Codable, CaseIterable {
    case cleaning
    case kitchen
    case bathroom
    case laundry
    case trash
    case shopping
    case other
}

// MARK: - Mock Data


extension TaskModel {

    static let mock = TaskModel(
        taskId: "task_123",
        householdId: "house_123",
        createdAt: .now,
        title: "Take out trash",
        description: "Take the bins outside",
        assignedToUserId: "1",
        createdByUserId: "2",
        dueDate: dateInCurrentWeek(
            dayOffset: 0,
            hour: 19
        ),
        isAllDay: false,
        status: .pending,
        category: .trash
    )

    static let mockCompleted = TaskModel(
        taskId: "task_456",
        householdId: "house_123",
        createdAt: .now,
        title: "Clean kitchen",
        assignedToUserId: "2",
        createdByUserId: "1",
        dueDate: dateInCurrentWeek(
            dayOffset: 2,
            hour: 17,
            minute: 30
        ),
        isAllDay: false,
        status: .completed,
        category: .kitchen
    )

    static let mockList: [TaskModel] = [
        // Monday
        TaskModel(
            taskId: "task_1",
            householdId: "house_123",
            createdAt: .now,
            title: "Vacuum living room",
            description: "Vacuum under the sofa as well",
            assignedToUserId: "3",
            createdByUserId: "1",
            dueDate: dateInCurrentWeek(
                dayOffset: 0,
                hour: 18
            ),
            isAllDay: false,
            status: .pending,
            category: .cleaning
        ),

        // Tuesday
        TaskModel(
            taskId: "task_2",
            householdId: "house_123",
            createdAt: .now,
            title: "Take out recycling",
            assignedToUserId: "1",
            createdByUserId: "2",
            dueDate: dateInCurrentWeek(
                dayOffset: 1
            ),
            isAllDay: true,
            status: .pending,
            category: .trash
        ),

        // Wednesday
        TaskModel(
            taskId: "task_3",
            householdId: "house_123",
            createdAt: .now,
            title: "Clean bathroom",
            description: "Clean the shower and mirror",
            assignedToUserId: "2",
            createdByUserId: "1",
            dueDate: dateInCurrentWeek(
                dayOffset: 2,
                hour: 10
            ),
            isAllDay: false,
            status: .pending,
            category: .bathroom
        ),

        TaskModel(
            taskId: "task_4",
            householdId: "house_123",
            createdAt: .now,
            title: "Do laundry",
            assignedToUserId: "1",
            createdByUserId: "2",
            dueDate: dateInCurrentWeek(
                dayOffset: 2,
                hour: 17,
                minute: 30
            ),
            isAllDay: false,
            status: .completed,
            category: .laundry
        ),

        TaskModel(
            taskId: "task_5",
            householdId: "house_123",
            createdAt: .now,
            title: "Take out rubbish",
            assignedToUserId: "3",
            createdByUserId: "1",
            dueDate: dateInCurrentWeek(
                dayOffset: 2,
                hour: 20
            ),
            isAllDay: false,
            status: .pending,
            category: .trash
        ),

        // Thursday
        TaskModel(
            taskId: "task_6",
            householdId: "house_123",
            createdAt: .now,
            title: "Clean kitchen",
            description: "Clean worktops and cooker",
            assignedToUserId: "1",
            createdByUserId: "2",
            dueDate: dateInCurrentWeek(
                dayOffset: 3,
                hour: 19
            ),
            isAllDay: false,
            status: .pending,
            category: .kitchen
        ),

        // Friday
        TaskModel(
            taskId: "task_7",
            householdId: "house_123",
            createdAt: .now,
            title: "Empty dishwasher",
            assignedToUserId: "2",
            createdByUserId: "1",
            dueDate: dateInCurrentWeek(
                dayOffset: 4
            ),
            isAllDay: true,
            status: .pending,
            category: .kitchen
        ),

        // Saturday
        TaskModel(
            taskId: "task_8",
            householdId: "house_123",
            createdAt: .now,
            title: "Mop the floors",
            assignedToUserId: "2",
            createdByUserId: "1",
            dueDate: dateInCurrentWeek(
                dayOffset: 5,
                hour: 11
            ),
            isAllDay: false,
            status: .pending,
            category: .cleaning
        ),

        TaskModel(
            taskId: "task_9",
            householdId: "house_123",
            createdAt: .now,
            title: "Clean windows",
            assignedToUserId: "3",
            createdByUserId: "1",
            dueDate: dateInCurrentWeek(
                dayOffset: 5,
                hour: 13
            ),
            isAllDay: false,
            status: .pending,
            category: .cleaning
        )
    ]

    // MARK: - Date Helper

    private static func dateInCurrentWeek(
        dayOffset: Int,
        hour: Int? = nil,
        minute: Int = 0
    ) -> Date {
        var calendar = Calendar.autoupdatingCurrent
        calendar.firstWeekday = 2

        let today = calendar.startOfDay(for: .now)
        let currentWeekday = calendar.component(
            .weekday,
            from: today
        )

        let daysSinceMonday = (currentWeekday + 5) % 7

        guard
            let monday = calendar.date(
                byAdding: .day,
                value: -daysSinceMonday,
                to: today
            ),
            let selectedDay = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: monday
            )
        else {
            return .now
        }

        guard let hour else {
            return selectedDay
        }

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: selectedDay
        ) ?? selectedDay
    }
}
