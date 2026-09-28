import Foundation
import Testing
@testable import HouseMate

@Suite("TaskManager")
struct TaskManagerTests {

    @Test("Cached tasks remain visible when the backend is offline")
    @MainActor
    func keepsCachedTasksWhenBackendIsOffline() async {
        let householdID = "offline-\(UUID().uuidString)"
        let cachedTask = makeTask(id: "cached-task", householdID: householdID)
        HomeDataCache.save([cachedTask], feature: .tasks, householdID: householdID)
        let manager = TaskManager(
            service: OfflineTaskService(),
            notificationService: MockLocalNotificationService()
        )

        do {
            try await manager.fetchTasks(
                householdID: householdID,
                currentUserID: "user"
            )
            Issue.record("Offline service should fail the Firebase refresh")
        } catch {
            #expect(error as? OfflineTestError == .unavailable)
        }

        #expect(manager.tasks == [cachedTask])
    }

    @Test("Pagination loads every task without duplicates")
    @MainActor
    func loadsEveryPageWithoutDuplicates() async throws {
        let householdID = "tasks-\(UUID().uuidString)"
        let start = Calendar.current.startOfDay(for: .now).addingTimeInterval(3_600)
        let tasks = (0..<25).map { index in
            makeTask(
                id: String(format: "task-%02d", index),
                householdID: householdID,
                dueDate: start.addingTimeInterval(Double(index) * 60)
            )
        }
        let manager = TaskManager(
            service: MockTaskService(tasks: tasks),
            notificationService: MockLocalNotificationService()
        )

        try await manager.fetchTasks(householdID: householdID, currentUserID: "user")

        #expect(manager.tasks.count == 20)
        #expect(manager.canLoadMore)

        try await manager.loadMoreTasks()

        #expect(manager.tasks.count == 25)
        #expect(Set(manager.tasks.map(\.id)).count == 25)
        #expect(!manager.canLoadMore)
    }

    @Test("Create, complete and delete keep the task list consistent")
    @MainActor
    func createsCompletesAndDeletesTask() async throws {
        let householdID = "tasks-\(UUID().uuidString)"
        let manager = TaskManager(
            service: MockTaskService(tasks: []),
            notificationService: MockLocalNotificationService()
        )
        try await manager.fetchTasks(householdID: householdID, currentUserID: "user")
        let task = makeTask(id: "new-task", householdID: householdID)

        try await manager.createTask(task)
        #expect(manager.tasks == [task])

        try await manager.toggleStatus(task)
        #expect(manager.tasks.first?.status == .completed)

        let completedTask = try #require(manager.tasks.first)
        try await manager.deleteTask(completedTask)
        #expect(manager.tasks.isEmpty)
    }
}
