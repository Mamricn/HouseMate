//
//  BillManager.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class BillManager {

    private let service: any BillServiceProtocol
    private let notificationService: any LocalNotificationServiceProtocol
    private var activeObservation: ServiceObservation?
    private var paidObservation: ServiceObservation?
    private var activeBills: [BillModel] = []
    private var paidBills: [BillModel] = []

    private(set) var bills: [BillModel] = []

    init(service: any BillServiceProtocol, notificationService: any LocalNotificationServiceProtocol) {
        self.service = service
        self.notificationService = notificationService
    }

    func fetchBills(householdID: String) async throws {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)

        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else {
            return
        }

        cancelObservations()

        activeObservation = service.observeActiveBills(householdID: householdID, limit: 40) { [weak self] result in
            if case .success(let bills) = result {
                self?.activeBills = bills
                self?.mergeObservedBills(today: today)
            }
        }
        paidObservation = service.observeRecentlyPaidBills(householdID: householdID, paidAfter: thirtyDaysAgo, limit: 20) { [weak self] result in
            if case .success(let bills) = result {
                self?.paidBills = bills
                self?.mergeObservedBills(today: today)
            }
        }

        if activeObservation == nil || paidObservation == nil {
            activeBills = try await service.fetchActiveBills(householdID: householdID, limit: 40)
            paidBills = try await service.fetchRecentlyPaidBills(householdID: householdID, paidAfter: thirtyDaysAgo, limit: 20)
            mergeObservedBills(today: today)
        }
    }

    func createBill(_ bill: BillModel) async throws {
        try await service.createBill(bill)
        if !bills.contains(where: { $0.billId == bill.billId }) {
            bills.append(bill)
        }
        sortBills()
        trimBills()

        if bill.notificationAdvance != nil {
            do {
                let authorized = try await notificationService.requestAuthorization()
                if authorized { try await notificationService.scheduleBill(bill) }
            } catch { }
        }

        synchronizeNotifications()
    }

    func markAsPaid(_ bill: BillModel, paidByUserID: String) async throws {
        let paidAt = Date.now
        let nextBill = makeNextOccurrence(for: bill, createdAt: paidAt)

        try await service.markBillAsPaid(
            bill,
            paidByUserID: paidByUserID,
            paidAt: paidAt,
            nextBill: nextBill
        )

        guard let index = bills.firstIndex(where: { $0.billId == bill.billId }) else {
            return
        }

        bills[index].status = .paid
        bills[index].paidByUserId = paidByUserID
        bills[index].paidAt = paidAt

        if let nextBill,
           !bills.contains(where: { $0.billId == nextBill.billId }) {
            bills.append(nextBill)
        }

        sortBills()
        trimBills()
        notificationService.cancelBill(billID: bill.billId)
        synchronizeNotifications()
    }

    func deleteBill(_ bill: BillModel) async throws {
        try await service.deleteBill(billID: bill.billId, householdID: bill.householdId)
        bills.removeAll { $0.billId == bill.billId }
        notificationService.cancelBill(billID: bill.billId)
    }

    func clearBills() {
        cancelObservations()
        activeBills = []
        paidBills = []
        for bill in bills { notificationService.cancelBill(billID: bill.billId) }
        bills = []
    }

    func refreshNotifications() {
        synchronizeNotifications()
    }

    private func mergeObservedBills(today: Date) {
        var active = activeBills

        for index in active.indices where active[index].dueDate.map({ $0 < today }) == true {
            active[index].status = .overdue
        }

        let availablePaidSlots = max(0, 40 - active.count)
        bills = active + Array(paidBills.prefix(availablePaidSlots))
        sortBills()
        synchronizeNotifications()
    }

    private func cancelObservations() {
        activeObservation?.cancel()
        paidObservation?.cancel()
        activeObservation = nil
        paidObservation = nil
    }

    private func makeNextOccurrence(for bill: BillModel, createdAt: Date) -> BillModel? {
        guard bill.isRecurring,
              let recurrence = bill.recurrence,
              let dueDate = bill.dueDate,
              let nextDueDate = nextDueDate(after: dueDate, recurrence: recurrence) else {
            return nil
        }

        let seriesID = bill.recurrenceSeriesId ?? bill.billId
        let nextBillID = "\(seriesID)_\(Int(nextDueDate.timeIntervalSince1970))"

        return BillModel(
            billId: nextBillID,
            householdId: bill.householdId,
            createdAt: createdAt,
            title: bill.title,
            amount: bill.amount,
            dueDate: nextDueDate,
            category: bill.category,
            createdByUserId: bill.createdByUserId,
            status: .upcoming,
            isRecurring: true,
            recurrence: recurrence,
            recurrenceSeriesId: seriesID,
            notificationAdvance: bill.notificationAdvance
        )
    }

    private func nextDueDate(after date: Date, recurrence: BillRecurrence) -> Date? {
        let calendar = Calendar.autoupdatingCurrent

        switch recurrence {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)

        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)

        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }

    private func sortBills() {
        bills.sort { firstBill, secondBill in
            if firstBill.status == .paid && secondBill.status != .paid {
                return false
            }

            if firstBill.status != .paid && secondBill.status == .paid {
                return true
            }

            if firstBill.status == .paid {
                return (firstBill.paidAt ?? .distantPast) > (secondBill.paidAt ?? .distantPast)
            }

            return (firstBill.dueDate ?? .distantFuture) < (secondBill.dueDate ?? .distantFuture)
        }
    }

    private func trimBills() {
        guard bills.count > 40 else {
            return
        }

        let activeBills = bills.filter { $0.status != .paid }
        let paidBills = bills.filter { $0.status == .paid }
        let availablePaidSlots = max(0, 40 - activeBills.count)
        bills = Array(activeBills.prefix(40)) + Array(paidBills.prefix(availablePaidSlots))
    }

    private func synchronizeNotifications() {
        let bills = bills
        Task {
            do { try await notificationService.synchronizeBills(bills) }
            catch { }
        }
    }
}
