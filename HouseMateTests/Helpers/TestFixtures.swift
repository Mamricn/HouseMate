import Foundation
@testable import HouseMate

@MainActor
func makeTask(
    id: String,
    householdID: String,
    dueDate: Date = .now.addingTimeInterval(3_600)
) -> TaskModel {
    TaskModel(
        taskId: id,
        householdId: householdID,
        createdAt: .now,
        title: id,
        assignedToUserId: "user",
        createdByUserId: "owner",
        dueDate: dueDate
    )
}

enum OfflineTestError: Error, Equatable {
    case unavailable
}

@MainActor
final class OfflineTaskService: TaskServiceProtocol {
    func fetchTasksPage(
        householdID: String,
        from startDate: Date,
        to endDate: Date,
        limit: Int,
        after cursor: TaskPageCursor?
    ) async throws -> TaskPage {
        throw OfflineTestError.unavailable
    }

    func createTask(_ task: TaskModel) async throws {
        throw OfflineTestError.unavailable
    }

    func updateTaskStatus(
        taskID: String,
        householdID: String,
        status: TaskStatus
    ) async throws {
        throw OfflineTestError.unavailable
    }

    func deleteTask(taskID: String, householdID: String) async throws {
        throw OfflineTestError.unavailable
    }
}
