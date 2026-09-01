//
//  MockBillService.swift
//  HouseMate
//

import Foundation

@MainActor
final class MockBillService: BillServiceProtocol {

    private var bills: [BillModel]

    init(bills: [BillModel]) {
        self.bills = bills
    }

    convenience init() {
        self.init(bills: BillModel.mockList)
    }

    func fetchActiveBills(householdID: String, limit: Int) async throws -> [BillModel] {
        Array(
            bills
                .filter { $0.householdId == householdID && $0.status != .paid }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
                .prefix(limit)
        )
    }

    func fetchRecentlyPaidBills(householdID: String, paidAfter date: Date, limit: Int) async throws -> [BillModel] {
        Array(
            bills
                .filter { bill in
                    bill.householdId == householdID
                        && bill.status == .paid
                        && (bill.paidAt ?? .distantPast) >= date
                }
                .sorted { ($0.paidAt ?? .distantPast) > ($1.paidAt ?? .distantPast) }
                .prefix(limit)
        )
    }

    func createBill(_ bill: BillModel) async throws {
        bills.append(bill)
    }

    func markBillAsPaid(_ bill: BillModel, paidByUserID: String, paidAt: Date, nextBill: BillModel?) async throws {
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
    }

    func deleteBill(billID: String, householdID: String) async throws {
        bills.removeAll { $0.billId == billID && $0.householdId == householdID }
    }
}
