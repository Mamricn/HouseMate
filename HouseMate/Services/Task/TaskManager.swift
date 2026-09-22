//
//  TaskManager.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class TaskManager {

    private let pageSize = 20
    private let service: any TaskServiceProtocol
    private let notificationService: any LocalNotificationServiceProtocol
    private var observation: ServiceObservation?
    private var currentUserID: String?
    private var currentHouseholdID: String?
    private var currentStartDate: Date?
    private var currentEndDate: Date?
    private var nextCursor: TaskPageCursor?
    private var firstPageTasks: [TaskModel] = []
    private var additionalTasks: [TaskModel] = []
    private var isShowingCachedTasks = false

    private(set) var tasks: [TaskModel] = []
    private(set) var canLoadMore = false
    private(set) var isLoadingMore = false

    init(service: any TaskServiceProtocol, notificationService: any LocalNotificationServiceProtocol) {
        self.service = service
        self.notificationService = notificationService
    }

    func fetchTasks(householdID: String, currentUserID: String) async throws {
        self.currentUserID = currentUserID
        currentHouseholdID = householdID
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)

        guard let startDate = calendar.date(byAdding: .day, value: -7, to: today),
              let endDate = calendar.date(byAdding: .day, value: 31, to: today) else {
            return
        }

        observation?.cancel()
        firstPageTasks = []
        additionalTasks = []
        nextCursor = nil
        canLoadMore = false

        currentStartDate = startDate
        currentEndDate = endDate
        restoreCache(
            householdID: householdID,
            startDate: startDate,
            endDate: endDate
        )

        if let observation = service.observeTasks(householdID: householdID, from: startDate, to: endDate, limit: pageSize, onChange: { [weak self] result in
            switch result {
            case .success(let tasks):
                self?.applyFirstPage(tasks)
            case .failure:
                break
            }
        }) {
            self.observation = observation
        } else {
            let page = try await service.fetchTasksPage(
                householdID: householdID,
                from: startDate,
                to: endDate,
                limit: pageSize,
                after: nil
            )
            firstPageTasks = page.tasks
            nextCursor = page.nextCursor
            canLoadMore = page.tasks.count == pageSize && page.nextCursor != nil
            mergePages()
            saveCache()
            synchronizeNotifications()
        }
    }

    func loadMoreTasks() async throws {
        guard !isLoadingMore,
              canLoadMore,
              let householdID = currentHouseholdID,
              let startDate = currentStartDate,
              let endDate = currentEndDate,
              let cursor = nextCursor else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let page = try await service.fetchTasksPage(
            householdID: householdID,
            from: startDate,
            to: endDate,
            limit: pageSize,
            after: cursor
        )

        additionalTasks.append(contentsOf: page.tasks)
        nextCursor = page.nextCursor
        canLoadMore = page.tasks.count == pageSize && page.nextCursor != nil
        mergePages()
        saveCache()
        synchronizeNotifications()
    }

    func createTask(_ task: TaskModel) async throws {
        try await service.createTask(task)
        if !tasks.contains(where: { $0.taskId == task.taskId }) {
            tasks.append(task)
        }
        if !firstPageTasks.contains(where: { $0.id == task.id }) {
            firstPageTasks.append(task)
        }
        sortTasks()
        saveCache()

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
        updateCachedTask(tasks[index])
        saveCache()

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
        firstPageTasks.removeAll { $0.id == task.id }
        additionalTasks.removeAll { $0.id == task.id }
        saveCache()
        notificationService.cancelTask(taskID: task.taskId)
    }

    func clearTasks() {
        observation?.cancel()
        observation = nil
        currentUserID = nil
        currentHouseholdID = nil
        currentStartDate = nil
        currentEndDate = nil
        nextCursor = nil
        firstPageTasks = []
        additionalTasks = []
        canLoadMore = false
        isLoadingMore = false
        isShowingCachedTasks = false
        for task in tasks { notificationService.cancelTask(taskID: task.taskId) }
        tasks = []
    }

    func refreshNotifications() {
        synchronizeNotifications()
    }

    private func sortTasks() {
        tasks.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private func applyFirstPage(_ fetchedTasks: [TaskModel]) {
        if isShowingCachedTasks {
            additionalTasks = []
            isShowingCachedTasks = false
        }
        firstPageTasks = fetchedTasks
        nextCursor = fetchedTasks.last.flatMap { task in
            task.dueDate.map { TaskPageCursor(dueDate: $0, documentID: task.id) }
        }
        canLoadMore = fetchedTasks.count == pageSize
        mergePages()
        saveCache()
        synchronizeNotifications()
    }

    private func mergePages() {
        var tasksByID: [String: TaskModel] = [:]
        for task in firstPageTasks + additionalTasks {
            tasksByID[task.id] = task
        }
        tasks = tasksByID.values.sorted {
            let lhsDate = $0.dueDate ?? .distantFuture
            let rhsDate = $1.dueDate ?? .distantFuture
            return lhsDate == rhsDate ? $0.id < $1.id : lhsDate < rhsDate
        }
    }

    private func updateCachedTask(_ task: TaskModel) {
        if let index = firstPageTasks.firstIndex(where: { $0.id == task.id }) {
            firstPageTasks[index] = task
        }
        if let index = additionalTasks.firstIndex(where: { $0.id == task.id }) {
            additionalTasks[index] = task
        }
    }

    private func restoreCache(
        householdID: String,
        startDate: Date,
        endDate: Date
    ) {
        guard let cached: [TaskModel] = HomeDataCache.load(
            feature: .tasks,
            householdID: householdID
        ) else { return }

        let relevant = cached.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= startDate && dueDate < endDate
        }

        firstPageTasks = Array(relevant.prefix(pageSize))
        additionalTasks = Array(relevant.dropFirst(pageSize))
        isShowingCachedTasks = !relevant.isEmpty
        mergePages()
    }

    private func saveCache() {
        guard let currentHouseholdID else { return }
        HomeDataCache.save(
            tasks,
            feature: .tasks,
            householdID: currentHouseholdID
        )
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
