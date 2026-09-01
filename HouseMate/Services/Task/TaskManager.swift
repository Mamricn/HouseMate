//
//  TaskManager.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class TaskManager {

    private let service: any TaskServiceProtocol
    private let notificationService: any LocalNotificationServiceProtocol
    private var observation: ServiceObservation?
    private var currentUserID: String?

    private(set) var tasks: [TaskModel] = []

    init(service: any TaskServiceProtocol, notificationService: any LocalNotificationServiceProtocol) {
        self.service = service
        self.notificationService = notificationService
    }

    func fetchTasks(householdID: String, currentUserID: String) async throws {
        self.currentUserID = currentUserID
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)

        guard let startDate = calendar.date(byAdding: .day, value: -7, to: today),
              let endDate = calendar.date(byAdding: .day, value: 31, to: today) else {
            return
        }

        observation?.cancel()

        if let observation = service.observeTasks(householdID: householdID, from: startDate, to: endDate, limit: 100, onChange: { [weak self] result in
            switch result {
            case .success(let tasks):
                self?.tasks = tasks
                self?.synchronizeNotifications()
            case .failure:
                break
            }
        }) {
            self.observation = observation
        } else {
            tasks = try await service.fetchTasks(householdID: householdID, from: startDate, to: endDate, limit: 100)
            synchronizeNotifications()
        }
    }

    func createTask(_ task: TaskModel) async throws {
        try await service.createTask(task)
        if !tasks.contains(where: { $0.taskId == task.taskId }) {
            tasks.append(task)
        }
        sortTasks()

        if task.notificationAdvance != nil,
           task.assignedToUserId == currentUserID {
            do {
                let authorized = try await notificationService.requestAuthorization()
                if authorized, let currentUserID {
                    try await notificationService.scheduleTask(task, currentUserID: currentUserID)
                }
            } catch { }
        }

        synchronizeNotifications()
    }

    func toggleStatus(_ task: TaskModel) async throws {
        let newStatus: TaskStatus = task.status == .completed ? .pending : .completed

        try await service.updateTaskStatus(
            taskID: task.taskId,
            householdID: task.householdId,
            status: newStatus
        )

        guard let index = tasks.firstIndex(where: { $0.taskId == task.taskId }) else {
            return
        }

        tasks[index].status = newStatus

        if newStatus == .completed {
            notificationService.cancelTask(taskID: task.taskId)
        } else {
            synchronizeNotifications()
        }
    }

    func deleteTask(_ task: TaskModel) async throws {
        try await service.deleteTask(
            taskID: task.taskId,
            householdID: task.householdId
        )

        tasks.removeAll { $0.taskId == task.taskId }
        notificationService.cancelTask(taskID: task.taskId)
    }

    func clearTasks() {
        observation?.cancel()
        observation = nil
        currentUserID = nil
        for task in tasks { notificationService.cancelTask(taskID: task.taskId) }
        tasks = []
    }

    func refreshNotifications() {
        synchronizeNotifications()
    }

    private func sortTasks() {
        tasks.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private func synchronizeNotifications() {
        guard let currentUserID else { return }
        let tasks = tasks
        Task {
            do { try await notificationService.synchronizeTasks(tasks, currentUserID: currentUserID) }
            catch { }
        }
    }
}
