//
//  FirebaseShoppingService.swift
//  HouseMate
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseShoppingService: ShoppingServiceProtocol {

    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func fetchActiveItems(householdID: String, limit: Int) async throws -> [ShoppingItemModel] {
        let snapshot = try await itemsCollection(householdID: householdID)
            .whereField("is_purchased", isEqualTo: false)
            .limit(to: limit)
            .getDocuments()

        return try decode(snapshot)
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func fetchRecentlyPurchasedItems(householdID: String, purchasedAfter date: Date, limit: Int) async throws -> [ShoppingItemModel] {
        let snapshot = try await itemsCollection(householdID: householdID)
            .whereField("purchased_at", isGreaterThanOrEqualTo: date)
            .order(by: "purchased_at", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try decode(snapshot)
    }

    func observeActiveItems(householdID: String, limit: Int, onChange: @escaping (Result<[ShoppingItemModel], Error>) -> Void) -> ServiceObservation? {
        observe(
            query: itemsCollection(householdID: householdID)
                .whereField("is_purchased", isEqualTo: false)
                .limit(to: limit),
            sort: { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) },
            onChange: onChange
        )
    }

    func observeRecentlyPurchasedItems(householdID: String, purchasedAfter date: Date, limit: Int, onChange: @escaping (Result<[ShoppingItemModel], Error>) -> Void) -> ServiceObservation? {
        observe(
            query: itemsCollection(householdID: householdID)
                .whereField("purchased_at", isGreaterThanOrEqualTo: date)
                .order(by: "purchased_at", descending: true)
                .limit(to: limit),
            sort: { ($0.purchasedAt ?? .distantPast) > ($1.purchasedAt ?? .distantPast) },
            onChange: onChange
        )
    }

    func createItem(_ item: ShoppingItemModel) async throws {
        let data = try Firestore.Encoder().encode(item)

        try await itemsCollection(householdID: item.householdId)
            .document(item.itemId)
            .setData(data)
    }

    func updatePurchasedState(itemID: String, householdID: String, isPurchased: Bool, purchasedAt: Date?) async throws {
        let purchasedAtValue: Any

        if let purchasedAt {
            purchasedAtValue = purchasedAt
        } else {
            purchasedAtValue = FieldValue.delete()
        }

        try await itemsCollection(householdID: householdID)
            .document(itemID)
            .updateData([
                "is_purchased": isPurchased,
                "purchased_at": purchasedAtValue
            ])
    }

    func deleteItem(itemID: String, householdID: String) async throws {
        try await itemsCollection(householdID: householdID)
            .document(itemID)
            .delete()
    }

    func deleteItems(_ items: [ShoppingItemModel]) async throws {
        let batch = database.batch()

        for item in items {
            let reference = itemsCollection(householdID: item.householdId)
                .document(item.itemId)
            batch.deleteDocument(reference)
        }

        try await batch.commit()
    }

    private func itemsCollection(householdID: String) -> CollectionReference {
        database
            .collection("households")
            .document(householdID)
            .collection("shopping_items")
    }

    private func decode(_ snapshot: QuerySnapshot) throws -> [ShoppingItemModel] {
        try snapshot.documents.map { document in
            try Firestore.Decoder().decode(ShoppingItemModel.self, from: document.data())
        }
    }

    private func observe(query: Query, sort: @escaping (ShoppingItemModel, ShoppingItemModel) -> Bool, onChange: @escaping (Result<[ShoppingItemModel], Error>) -> Void) -> ServiceObservation {
        let listener = query.addSnapshotListener { snapshot, error in
            if let error {
                onChange(.failure(error))
                return
            }

            do {
                let items = try snapshot?.documents.map {
                    try Firestore.Decoder().decode(ShoppingItemModel.self, from: $0.data())
                } ?? []
                onChange(.success(items.sorted(by: sort)))
            } catch {
                onChange(.failure(error))
            }
        }

        return ServiceObservation(cancellation: listener.remove)
    }
}
