//
//  MockTaskService.swift
//  HouseMate
//

import Foundation

@MainActor
final class MockTaskService: TaskServiceProtocol {

    private var tasks: [TaskModel]

    init(tasks: [TaskModel]) {
        self.tasks = tasks
    }

    convenience init() {
        self.init(tasks: TaskModel.mockList)
    }

    func fetchTasks(householdID: String, from startDate: Date, to endDate: Date, limit: Int) async throws -> [TaskModel] {
        tasks
            .filter { task in
                guard let dueDate = task.dueDate else {
                    return false
                }

                return task.householdId == householdID
                    && dueDate >= startDate
                    && dueDate < endDate
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(limit)
            .map { $0 }
    }

    func createTask(_ task: TaskModel) async throws {
        tasks.append(task)
    }

    func updateTaskStatus(taskID: String, householdID: String, status: TaskStatus) async throws {
        guard let index = tasks.firstIndex(where: {
            $0.taskId == taskID && $0.householdId == householdID
        }) else {
            return
        }

        tasks[index].status = status
    }

    func deleteTask(taskID: String, householdID: String) async throws {
        tasks.removeAll {
            $0.taskId == taskID && $0.householdId == householdID
        }
    }
}
