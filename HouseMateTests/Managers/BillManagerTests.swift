import Foundation
import Testing
@testable import HouseMate

@Suite("BillManager")
struct BillManagerTests {

    @Test("Paying a recurring bill creates its next occurrence")
    @MainActor
    func createsNextRecurringBillAfterPayment() async throws {
        let householdID = "bills-\(UUID().uuidString)"
        let dueDate = try #require(Calendar.current.date(byAdding: .day, value: 2, to: .now))
        let bill = BillModel(
            billId: "rent",
            householdId: householdID,
            createdAt: .now,
            title: "Rent",
            amount: 900,
            dueDate: dueDate,
            category: .rent,
            createdByUserId: "owner",
            status: .upcoming,
            isRecurring: true,
            recurrence: .monthly
        )
        let manager = BillManager(
            service: MockBillService(bills: [bill]),
            notificationService: MockLocalNotificationService()
        )
        try await manager.fetchBills(householdID: householdID)

        try await manager.markAsPaid(bill, paidByUserID: "member")

        #expect(manager.bills.count == 2)
        let paid = try #require(manager.bills.first { $0.billId == bill.billId })
        #expect(paid.status == .paid)
        #expect(paid.paidByUserId == "member")
        #expect(paid.paidAt != nil)

        let next = try #require(manager.bills.first { $0.billId != bill.billId })
        #expect(next.status == .upcoming)
        #expect(next.recurrenceSeriesId == bill.billId)
        #expect((next.dueDate ?? .distantPast) > dueDate)
    }
}
