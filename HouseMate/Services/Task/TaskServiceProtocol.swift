//
//  TaskServiceProtocol.swift
//  HouseMate
//

import Foundation

struct TaskPageCursor {
    let dueDate: Date
    let documentID: String
}

struct TaskPage {
    let tasks: [TaskModel]
    let nextCursor: TaskPageCursor?
}

@MainActor
protocol TaskServiceProtocol: AnyObject {

    func fetchTasksPage(
        householdID: String,
        from startDate: Date,
        to endDate: Date,
        limit: Int,
        after cursor: TaskPageCursor?
    ) async throws -> TaskPage

    func observeTasks(householdID: String, from startDate: Date, to endDate: Date, limit: Int, onChange: @escaping (Result<[TaskModel], Error>) -> Void) -> ServiceObservation?

    func createTask(_ task: TaskModel) async throws

    func updateTaskStatus(taskID: String, householdID: String, status: TaskStatus) async throws

    func deleteTask(taskID: String, householdID: String) async throws
}

extension TaskServiceProtocol {

    func observeTasks(householdID: String, from startDate: Date, to endDate: Date, limit: Int, onChange: @escaping (Result<[TaskModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }
}
