//
//  TaskServiceProtocol.swift
//  HouseMate
//

import Foundation

@MainActor
protocol TaskServiceProtocol: AnyObject {

    func fetchTasks(householdID: String, from startDate: Date, to endDate: Date, limit: Int) async throws -> [TaskModel]

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
