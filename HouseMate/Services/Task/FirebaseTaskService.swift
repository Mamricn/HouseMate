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

    func fetchTasks(householdID: String, from startDate: Date, to endDate: Date, limit: Int) async throws -> [TaskModel] {
        let snapshot = try await tasksCollection(householdID: householdID)
            .whereField("due_date", isGreaterThanOrEqualTo: startDate)
            .whereField("due_date", isLessThan: endDate)
            .order(by: "due_date")
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents
            .map { document in
                try Firestore.Decoder().decode(TaskModel.self, from: document.data())
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    func observeTasks(householdID: String, from startDate: Date, to endDate: Date, limit: Int, onChange: @escaping (Result<[TaskModel], Error>) -> Void) -> ServiceObservation? {
        let listener = tasksCollection(householdID: householdID)
            .whereField("due_date", isGreaterThanOrEqualTo: startDate)
            .whereField("due_date", isLessThan: endDate)
            .order(by: "due_date")
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
        let data = try Firestore.Encoder().encode(task)

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
