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

    func fetchTasksPage(
        householdID: String,
        from startDate: Date,
        to endDate: Date,
        limit: Int,
        after cursor: TaskPageCursor?
    ) async throws -> TaskPage {
        let matchingTasks = tasks
            .filter { task in
                guard let dueDate = task.dueDate else {
                    return false
                }

                return task.householdId == householdID
                    && dueDate >= startDate
                    && dueDate < endDate
            }
            .sorted {
                let lhsDate = $0.dueDate ?? .distantFuture
                let rhsDate = $1.dueDate ?? .distantFuture
                return lhsDate == rhsDate ? $0.id < $1.id : lhsDate < rhsDate
            }
            .filter { task in
                guard let cursor, let dueDate = task.dueDate else { return true }
                return dueDate > cursor.dueDate
                    || (dueDate == cursor.dueDate && task.id > cursor.documentID)
            }
            .prefix(limit)
            .map { $0 }

        let nextCursor = matchingTasks.last.flatMap { task in
            task.dueDate.map { TaskPageCursor(dueDate: $0, documentID: task.id) }
        }

        return TaskPage(tasks: matchingTasks, nextCursor: nextCursor)
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
