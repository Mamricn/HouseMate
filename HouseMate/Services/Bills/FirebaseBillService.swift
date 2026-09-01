//
//  FirebaseBillService.swift
//  HouseMate
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseBillService: BillServiceProtocol {

    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func fetchActiveBills(householdID: String, limit: Int) async throws -> [BillModel] {
        let snapshot = try await billsCollection(householdID: householdID)
            .whereField("status", in: [BillStatus.upcoming.rawValue, BillStatus.overdue.rawValue])
            .limit(to: limit)
            .getDocuments()

        return try decode(snapshot)
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    func fetchRecentlyPaidBills(householdID: String, paidAfter date: Date, limit: Int) async throws -> [BillModel] {
        let snapshot = try await billsCollection(householdID: householdID)
            .whereField("paid_at", isGreaterThanOrEqualTo: date)
            .order(by: "paid_at", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try decode(snapshot)
    }

    func observeActiveBills(householdID: String, limit: Int, onChange: @escaping (Result<[BillModel], Error>) -> Void) -> ServiceObservation? {
        observe(
            query: billsCollection(householdID: householdID)
                .whereField("status", in: [BillStatus.upcoming.rawValue, BillStatus.overdue.rawValue])
                .limit(to: limit),
            sort: { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) },
            onChange: onChange
        )
    }

    func observeRecentlyPaidBills(householdID: String, paidAfter date: Date, limit: Int, onChange: @escaping (Result<[BillModel], Error>) -> Void) -> ServiceObservation? {
        observe(
            query: billsCollection(householdID: householdID)
                .whereField("paid_at", isGreaterThanOrEqualTo: date)
                .order(by: "paid_at", descending: true)
                .limit(to: limit),
            sort: { ($0.paidAt ?? .distantPast) > ($1.paidAt ?? .distantPast) },
            onChange: onChange
        )
    }

    func createBill(_ bill: BillModel) async throws {
        let data = try Firestore.Encoder().encode(bill)

        try await billsCollection(householdID: bill.householdId)
            .document(bill.billId)
            .setData(data)
    }

    func markBillAsPaid(_ bill: BillModel, paidByUserID: String, paidAt: Date, nextBill: BillModel?) async throws {
        let billReference = billsCollection(householdID: bill.householdId)
            .document(bill.billId)
        let batch = database.batch()

        batch.updateData(
            [
                "status": BillStatus.paid.rawValue,
                "paid_by_user_id": paidByUserID,
                "paid_at": paidAt
            ],
            forDocument: billReference
        )

        if let nextBill {
            let nextBillData = try Firestore.Encoder().encode(nextBill)
            let nextBillReference = billsCollection(householdID: nextBill.householdId)
                .document(nextBill.billId)
            batch.setData(nextBillData, forDocument: nextBillReference, merge: false)
        }

        try await batch.commit()
    }

    func deleteBill(billID: String, householdID: String) async throws {
        try await billsCollection(householdID: householdID)
            .document(billID)
            .delete()
    }

    private func billsCollection(householdID: String) -> CollectionReference {
        database
            .collection("households")
            .document(householdID)
            .collection("bills")
    }

    private func decode(_ snapshot: QuerySnapshot) throws -> [BillModel] {
        try snapshot.documents.map { document in
            try Firestore.Decoder().decode(BillModel.self, from: document.data())
        }
    }

    private func observe(query: Query, sort: @escaping (BillModel, BillModel) -> Bool, onChange: @escaping (Result<[BillModel], Error>) -> Void) -> ServiceObservation {
        let listener = query.addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            do {
                let bills = try snapshot?.documents.map {
                    try Firestore.Decoder().decode(BillModel.self, from: $0.data())
                } ?? []
                onChange(.success(bills.sorted(by: sort)))
            } catch {
                onChange(.failure(error))
            }
        }

        return ServiceObservation(cancellation: listener.remove)
    }
}
