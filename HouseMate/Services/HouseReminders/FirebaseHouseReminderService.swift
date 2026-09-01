//
//  FirebaseHouseReminderService.swift
//  HouseMate
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseHouseReminderService: HouseReminderServiceProtocol {

    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func fetchRecurringReminders(householdID: String, limit: Int) async throws -> [HouseReminderModel] {
        let snapshot = try await remindersCollection(householdID: householdID)
            .whereField("recurrence", isNotEqualTo: HouseReminderRecurrence.never.rawValue)
            .limit(to: limit)
            .getDocuments()

        return try decode(snapshot)
    }

    func fetchFutureReminders(householdID: String, from date: Date, limit: Int) async throws -> [HouseReminderModel] {
        let snapshot = try await remindersCollection(householdID: householdID)
            .whereField("first_occurrence_date", isGreaterThanOrEqualTo: date)
            .order(by: "first_occurrence_date")
            .limit(to: limit)
            .getDocuments()

        return try decode(snapshot)
    }

    func observeRecurringReminders(householdID: String, limit: Int, onChange: @escaping (Result<[HouseReminderModel], Error>) -> Void) -> ServiceObservation? {
        observe(
            query: remindersCollection(householdID: householdID)
                .whereField("recurrence", isNotEqualTo: HouseReminderRecurrence.never.rawValue)
                .limit(to: limit),
            onChange: onChange
        )
    }

    func observeFutureReminders(householdID: String, from date: Date, limit: Int, onChange: @escaping (Result<[HouseReminderModel], Error>) -> Void) -> ServiceObservation? {
        observe(
            query: remindersCollection(householdID: householdID)
                .whereField("first_occurrence_date", isGreaterThanOrEqualTo: date)
                .order(by: "first_occurrence_date")
                .limit(to: limit),
            onChange: onChange
        )
    }

    func createReminder(_ reminder: HouseReminderModel) async throws {
        let data = try Firestore.Encoder().encode(reminder)

        try await remindersCollection(householdID: reminder.householdId)
            .document(reminder.reminderId)
            .setData(data)
    }

    func deleteReminder(reminderID: String, householdID: String) async throws {
        try await remindersCollection(householdID: householdID)
            .document(reminderID)
            .delete()
    }

    private func remindersCollection(householdID: String) -> CollectionReference {
        database
            .collection("households")
            .document(householdID)
            .collection("house_reminders")
    }

    private func decode(_ snapshot: QuerySnapshot) throws -> [HouseReminderModel] {
        try snapshot.documents.map { document in
            try Firestore.Decoder().decode(HouseReminderModel.self, from: document.data())
        }
    }

    private func observe(query: Query, onChange: @escaping (Result<[HouseReminderModel], Error>) -> Void) -> ServiceObservation {
        let listener = query.addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            do {
                let reminders = try snapshot?.documents.map {
                    try Firestore.Decoder().decode(HouseReminderModel.self, from: $0.data())
                } ?? []
                onChange(.success(reminders))
            } catch {
                onChange(.failure(error))
            }
        }

        return ServiceObservation(cancellation: listener.remove)
    }
}
