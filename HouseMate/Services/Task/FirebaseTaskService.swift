//
//  FirebaseTaskService.swift
//  HouseMate
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseTaskService: TaskServiceProtocol {

    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func fetchTasksPage(
        householdID: String,
        from startDate: Date,
        to endDate: Date,
        limit: Int,
        after cursor: TaskPageCursor?
    ) async throws -> TaskPage {
        var query: Query = tasksCollection(householdID: householdID)
            .whereField("due_date", isGreaterThanOrEqualTo: startDate)
            .whereField("due_date", isLessThan: endDate)
            .order(by: "due_date")
            .order(by: FieldPath.documentID())

        if let cursor {
            query = query.start(after: [cursor.dueDate, cursor.documentID])
        }

        let snapshot = try await query
            .limit(to: limit)
            .getDocuments()

        let tasks = try snapshot.documents
            .map { document in
                try Firestore.Decoder().decode(TaskModel.self, from: document.data())
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

        let nextCursor = snapshot.documents.last.flatMap { document -> TaskPageCursor? in
            guard let dueDate = document.get("due_date") as? Timestamp else { return nil }
            return TaskPageCursor(dueDate: dueDate.dateValue(), documentID: document.documentID)
        }

        return TaskPage(tasks: tasks, nextCursor: nextCursor)
    }

    func observeTasks(householdID: String, from startDate: Date, to endDate: Date, limit: Int, onChange: @escaping (Result<[TaskModel], Error>) -> Void) -> ServiceObservation? {
        let listener = tasksCollection(householdID: householdID)
            .whereField("due_date", isGreaterThanOrEqualTo: startDate)
            .whereField("due_date", isLessThan: endDate)
            .order(by: "due_date")
            .order(by: FieldPath.documentID())
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                do {
                    let tasks = try snapshot?.documents.map {
                        try Firestore.Decoder().decode(TaskModel.self, from: $0.data())
                    } ?? []
                    onChange(.success(tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }))
                } catch {
                    onChange(.failure(error))
                }
            }

        return ServiceObservation(cancellation: listener.remove)
    }

    func createTask(_ task: TaskModel) async throws {
        var data = try Firestore.Encoder().encode(task)

        if let dueDate = task.dueDate,
           let advance = task.notificationAdvance,
           let reminderAt = advance.notificationDate(
            for: dueDate,
            useNineAM: task.isAllDay
           ) {
            data["reminder_at"] = reminderAt
        }

        try await tasksCollection(householdID: task.householdId)
            .document(task.taskId)
            .setData(data)
    }

    func updateTaskStatus(taskID: String, householdID: String, status: TaskStatus) async throws {
        try await tasksCollection(householdID: householdID)
            .document(taskID)
            .updateData(["status": status.rawValue])
    }

    func deleteTask(taskID: String, householdID: String) async throws {
        try await tasksCollection(householdID: householdID)
            .document(taskID)
            .delete()
    }

    private func tasksCollection(householdID: String) -> CollectionReference {
        database
            .collection("households")
            .document(householdID)
            .collection("tasks")
    }
}
