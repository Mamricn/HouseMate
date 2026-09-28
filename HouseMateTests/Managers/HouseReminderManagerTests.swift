import Foundation
import Testing
@testable import HouseMate

@Suite("HouseReminderManager")
struct HouseReminderManagerTests {

    @Test("Monthly reminder calculates the next future occurrence")
    func calculatesFutureMonthlyOccurrence() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/London"))
        let firstDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: 9))
        )
        let referenceDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 16, hour: 12))
        )
        let expectedDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 4, day: 15, hour: 9))
        )
        let reminder = HouseReminderModel(
            reminderId: "monthly",
            householdId: "home",
            createdByUserId: "creator",
            title: "Monthly check",
            firstOccurrenceDate: firstDate,
            recurrence: .monthly
        )

        #expect(reminder.nextOccurrence(after: referenceDate, calendar: calendar) == expectedDate)
    }

    @Test("Only the reminder creator or household owner can delete it")
    @MainActor
    func restrictsReminderDeletion() async throws {
        let householdID = "reminders-\(UUID().uuidString)"
        let reminder = HouseReminderModel(
            reminderId: "inspection",
            householdId: householdID,
            createdAt: .now,
            createdByUserId: "creator",
            title: "Inspection",
            firstOccurrenceDate: .now.addingTimeInterval(86_400)
        )
        let manager = HouseReminderManager(
            service: MockHouseReminderService(reminders: [reminder]),
            notificationService: MockLocalNotificationService()
        )
        try await manager.fetchReminders(householdID: householdID)

        try await manager.deleteReminder(
            reminder,
            currentUserID: "other-member",
            ownerUserID: "owner"
        )
        #expect(manager.reminders == [reminder])

        try await manager.deleteReminder(
            reminder,
            currentUserID: "owner",
            ownerUserID: "owner"
        )
        #expect(manager.reminders.isEmpty)
    }
}
