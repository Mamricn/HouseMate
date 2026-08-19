//
//  TaskModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


//
//  TaskModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import Foundation

struct TaskModel: Identifiable, Codable, Equatable {
    
    var id: String { taskId }
    
    let taskId: String
    let householdId: String
    
    let createdAt: Date?
    
    var title: String
    var description: String?
    
    var assignedToUserId: String?
    var createdByUserId: String
    
    var dueDate: Date?
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
        case status
        case category
    }
    
    
    var eventParameters: [String: Any] {
        
        let dict: [String: Any?] = [
            "task_\(CodingKeys.taskId.rawValue)": taskId,
            "task_\(CodingKeys.householdId.rawValue)": householdId,
            "task_\(CodingKeys.createdAt.rawValue)": createdAt,
            "task_\(CodingKeys.title.rawValue)": title,
            "task_\(CodingKeys.description.rawValue)": description,
            "task_\(CodingKeys.assignedToUserId.rawValue)": assignedToUserId,
            "task_\(CodingKeys.createdByUserId.rawValue)": createdByUserId,
            "task_\(CodingKeys.dueDate.rawValue)": dueDate,
            "task_\(CodingKeys.status.rawValue)": status.rawValue,
            "task_\(CodingKeys.category.rawValue)": category.rawValue
        ]
        
        return dict.compactMapValues { $0 }
    }
}
enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case completed
}
enum TaskCategory: String, Codable, CaseIterable {
    case cleaning
    case kitchen
    case bathroom
    case laundry
    case trash
    case shopping
    case other
}
extension TaskModel {
    
    static let mock = TaskModel(
        taskId: "task_123",
        householdId: "house_123",
        createdAt: .now,
        title: "Take out trash",
        description: "Take the bins outside",
        assignedToUserId: "1",
        createdByUserId: "2",
        dueDate: .now,
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
        dueDate: .now,
        status: .completed,
        category: .kitchen
    )
    
    
    static let mockList: [TaskModel] = [
        
        TaskModel(
            taskId: "1",
            householdId: "house_123",
            createdAt: .now,
            title: "Take out trash",
            assignedToUserId: "1",
            createdByUserId: "2",
            dueDate: .now,
            status: .completed,
            category: .trash
        ),
        
        TaskModel(
            taskId: "2",
            householdId: "house_123",
            createdAt: .now,
            title: "Clean bathroom",
            assignedToUserId: "2",
            createdByUserId: "1",
            dueDate: .now,
            status: .pending,
            category: .bathroom
        ),
        
        TaskModel(
            taskId: "3",
            householdId: "house_123",
            createdAt: .now,
            title: "Do laundry",
            assignedToUserId: "3",
            createdByUserId: "1",
            dueDate: .now,
            status: .completed,
            category: .laundry
        )
    ]
}
