//
//  HouseReminderServiceProtocol.swift
//  HouseMate
//

import Foundation

@MainActor
protocol HouseReminderServiceProtocol: AnyObject {

    func fetchRecurringReminders(householdID: String, limit: Int) async throws -> [HouseReminderModel]

    func fetchFutureReminders(householdID: String, from date: Date, limit: Int) async throws -> [HouseReminderModel]

    func observeRecurringReminders(householdID: String, limit: Int, onChange: @escaping (Result<[HouseReminderModel], Error>) -> Void) -> ServiceObservation?

    func observeFutureReminders(householdID: String, from date: Date, limit: Int, onChange: @escaping (Result<[HouseReminderModel], Error>) -> Void) -> ServiceObservation?

    func createReminder(_ reminder: HouseReminderModel) async throws

    func deleteReminder(reminderID: String, householdID: String) async throws
}

extension HouseReminderServiceProtocol {

    func observeRecurringReminders(householdID: String, limit: Int, onChange: @escaping (Result<[HouseReminderModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }

    func observeFutureReminders(householdID: String, from date: Date, limit: Int, onChange: @escaping (Result<[HouseReminderModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }
}
