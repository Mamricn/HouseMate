//
//  MockShoppingService.swift
//  HouseMate
//

import Foundation

@MainActor
final class MockShoppingService: ShoppingServiceProtocol {

    private var items: [ShoppingItemModel]

    init(items: [ShoppingItemModel]) {
        self.items = items
    }

    convenience init() {
        self.init(items: ShoppingItemModel.mockList)
    }

    func fetchActiveItems(householdID: String, limit: Int) async throws -> [ShoppingItemModel] {
        Array(
            items
                .filter { $0.householdId == householdID && !$0.isPurchased }
                .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
                .prefix(limit)
        )
    }

    func fetchRecentlyPurchasedItems(householdID: String, purchasedAfter date: Date, limit: Int) async throws -> [ShoppingItemModel] {
        Array(
            items
                .filter { item in
                    item.householdId == householdID
                        && item.isPurchased
                        && (item.purchasedAt ?? item.createdAt ?? .distantPast) >= date
                }
                .sorted { ($0.purchasedAt ?? .distantPast) > ($1.purchasedAt ?? .distantPast) }
                .prefix(limit)
        )
    }

    func createItem(_ item: ShoppingItemModel) async throws {
        items.append(item)
    }

    func updatePurchasedState(itemID: String, householdID: String, isPurchased: Bool, purchasedAt: Date?) async throws {
        guard let index = items.firstIndex(where: {
            $0.itemId == itemID && $0.householdId == householdID
        }) else {
            return
        }

        items[index].isPurchased = isPurchased
        items[index].purchasedAt = purchasedAt
    }

    func deleteItem(itemID: String, householdID: String) async throws {
        items.removeAll { $0.itemId == itemID && $0.householdId == householdID }
    }

    func deleteItems(_ items: [ShoppingItemModel]) async throws {
        let itemIDs = Set(items.map(\.itemId))
        self.items.removeAll { itemIDs.contains($0.itemId) }
    }
}
