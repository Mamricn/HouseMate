//
//  BillServiceProtocol.swift
//  HouseMate
//

import Foundation

@MainActor
protocol BillServiceProtocol: AnyObject {

    func fetchActiveBills(householdID: String, limit: Int) async throws -> [BillModel]

    func fetchRecentlyPaidBills(householdID: String, paidAfter date: Date, limit: Int) async throws -> [BillModel]

    func observeActiveBills(householdID: String, limit: Int, onChange: @escaping (Result<[BillModel], Error>) -> Void) -> ServiceObservation?

    func observeRecentlyPaidBills(householdID: String, paidAfter date: Date, limit: Int, onChange: @escaping (Result<[BillModel], Error>) -> Void) -> ServiceObservation?

    func createBill(_ bill: BillModel) async throws

    func markBillAsPaid(_ bill: BillModel, paidByUserID: String, paidAt: Date, nextBill: BillModel?) async throws

    func deleteBill(billID: String, householdID: String) async throws
}

extension BillServiceProtocol {

    func observeActiveBills(householdID: String, limit: Int, onChange: @escaping (Result<[BillModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }

    func observeRecentlyPaidBills(householdID: String, paidAfter date: Date, limit: Int, onChange: @escaping (Result<[BillModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }
}
