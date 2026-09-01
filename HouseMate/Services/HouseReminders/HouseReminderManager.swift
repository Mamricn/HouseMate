//
//  HouseReminderManager.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class HouseReminderManager {

    private let service: any HouseReminderServiceProtocol
    private let notificationService: any LocalNotificationServiceProtocol
    private var recurringObservation: ServiceObservation?
    private var futureObservation: ServiceObservation?
    private var recurringReminders: [HouseReminderModel] = []
    private var futureReminders: [HouseReminderModel] = []

    private(set) var reminders: [HouseReminderModel] = []

    init(service: any HouseReminderServiceProtocol, notificationService: any LocalNotificationServiceProtocol) {
        self.service = service
        self.notificationService = notificationService
    }

    func fetchReminders(householdID: String) async throws {
        let now = Date.now
        cancelObservations()
        recurringObservation = service.observeRecurringReminders(householdID: householdID, limit: 30) { [weak self] result in
            if case .success(let reminders) = result {
                self?.recurringReminders = reminders
                self?.mergeObservedReminders()
            }
        }
        futureObservation = service.observeFutureReminders(householdID: householdID, from: now, limit: 30) { [weak self] result in
            if case .success(let reminders) = result {
                self?.futureReminders = reminders
                self?.mergeObservedReminders()
            }
        }

        if recurringObservation == nil || futureObservation == nil {
            recurringReminders = try await service.fetchRecurringReminders(householdID: householdID, limit: 30)
            futureReminders = try await service.fetchFutureReminders(householdID: householdID, from: now, limit: 30)
            mergeObservedReminders()
        }
    }

    private func mergeObservedReminders() {
        let now = Date.now
        var remindersByID: [String: HouseReminderModel] = [:]

        for reminder in recurringReminders + futureReminders {
            if reminder.nextOccurrence(after: now) != nil {
                remindersByID[reminder.reminderId] = reminder
            }
        }

        reminders = Array(remindersByID.values)
            .sorted {
                ($0.nextOccurrence(after: now) ?? .distantFuture)
                    < ($1.nextOccurrence(after: now) ?? .distantFuture)
            }
            .prefix(30)
            .map { $0 }

        synchronizeNotifications()
    }

    func createReminder(_ reminder: HouseReminderModel) async throws {
        try await service.createReminder(reminder)
        if !reminders.contains(where: { $0.reminderId == reminder.reminderId }) {
            reminders.append(reminder)
        }
        sortReminders()
        reminders = Array(reminders.prefix(30))

        guard reminder.reminderAdvance != .none else {
            return
        }

        do {
            let isAuthorized = try await notificationService.requestAuthorization()

            if isAuthorized {
                try await notificationService.scheduleHouseReminder(reminder)
            }
        } catch {
            // The reminder is saved even if local notification scheduling fails.
        }
    }

    func deleteReminder(_ reminder: HouseReminderModel, currentUserID: String, ownerUserID: String) async throws {
        guard reminder.createdByUserId == currentUserID
                || currentUserID == ownerUserID else {
            return
        }

        try await service.deleteReminder(
            reminderID: reminder.reminderId,
            householdID: reminder.householdId
        )

        reminders.removeAll { $0.reminderId == reminder.reminderId }
        notificationService.cancelHouseReminder(reminderID: reminder.reminderId)
    }

    func clearReminders() {
        cancelObservations()

        for reminder in reminders {
            notificationService.cancelHouseReminder(reminderID: reminder.reminderId)
        }

        recurringReminders = []
        futureReminders = []
        reminders = []
    }

    func refreshNotifications() {
        synchronizeNotifications()
    }

    private func cancelObservations() {
        recurringObservation?.cancel()
        futureObservation?.cancel()
        recurringObservation = nil
        futureObservation = nil
    }

    private func sortReminders() {
        let now = Date.now

        reminders.sort {
            ($0.nextOccurrence(after: now) ?? .distantFuture)
                < ($1.nextOccurrence(after: now) ?? .distantFuture)
        }
    }

    private func synchronizeNotifications() {
        let reminders = reminders

        Task {
            do {
                try await notificationService.synchronizeHouseReminders(reminders)
            } catch {
                // Firestore remains the source of truth if local scheduling fails.
            }
        }
    }
}
