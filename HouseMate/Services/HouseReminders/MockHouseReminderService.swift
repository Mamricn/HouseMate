//
//  MockHouseReminderService.swift
//  HouseMate
//

import Foundation

@MainActor
final class MockHouseReminderService: HouseReminderServiceProtocol {

    private var reminders: [HouseReminderModel]

    init(reminders: [HouseReminderModel]) {
        self.reminders = reminders
    }

    convenience init() {
        self.init(reminders: HouseReminderModel.mockList)
    }

    func fetchRecurringReminders(householdID: String, limit: Int) async throws -> [HouseReminderModel] {
        Array(
            reminders
                .filter { $0.householdId == householdID && $0.recurrence != .never }
                .prefix(limit)
        )
    }

    func fetchFutureReminders(householdID: String, from date: Date, limit: Int) async throws -> [HouseReminderModel] {
        Array(
            reminders
                .filter { $0.householdId == householdID && $0.firstOccurrenceDate >= date }
                .sorted { $0.firstOccurrenceDate < $1.firstOccurrenceDate }
                .prefix(limit)
        )
    }

    func createReminder(_ reminder: HouseReminderModel) async throws {
        reminders.append(reminder)
    }

    func deleteReminder(reminderID: String, householdID: String) async throws {
        reminders.removeAll {
            $0.reminderId == reminderID && $0.householdId == householdID
        }
    }
}
