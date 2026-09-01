//
//  ShoppingManager.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class ShoppingManager {

    private let service: any ShoppingServiceProtocol
    private var activeObservation: ServiceObservation?
    private var purchasedObservation: ServiceObservation?
    private var activeItems: [ShoppingItemModel] = []
    private var purchasedItems: [ShoppingItemModel] = []

    private(set) var items: [ShoppingItemModel] = []

    init(service: any ShoppingServiceProtocol) {
        self.service = service
    }

    func fetchItems(householdID: String) async throws {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)

        guard let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) else {
            return
        }

        cancelObservations()

        activeObservation = service.observeActiveItems(householdID: householdID, limit: 40) { [weak self] result in
            if case .success(let items) = result {
                self?.activeItems = items
                self?.mergeObservedItems()
            }
        }
        purchasedObservation = service.observeRecentlyPurchasedItems(householdID: householdID, purchasedAfter: twoDaysAgo, limit: 20) { [weak self] result in
            if case .success(let items) = result {
                self?.purchasedItems = items
                self?.mergeObservedItems()
            }
        }

        if activeObservation == nil || purchasedObservation == nil {
            activeItems = try await service.fetchActiveItems(householdID: householdID, limit: 40)
            purchasedItems = try await service.fetchRecentlyPurchasedItems(householdID: householdID, purchasedAfter: twoDaysAgo, limit: 20)
            mergeObservedItems()
        }
    }

    func createItem(_ item: ShoppingItemModel) async throws {
        try await service.createItem(item)
        if !items.contains(where: { $0.itemId == item.itemId }) {
            items.append(item)
        }
        sortItems()
        trimItems()
    }

    func togglePurchased(_ item: ShoppingItemModel) async throws {
        let isPurchased = !item.isPurchased
        let purchasedAt: Date? = isPurchased ? .now : nil

        try await service.updatePurchasedState(
            itemID: item.itemId,
            householdID: item.householdId,
            isPurchased: isPurchased,
            purchasedAt: purchasedAt
        )

        guard let index = items.firstIndex(where: { $0.itemId == item.itemId }) else {
            return
        }

        items[index].isPurchased = isPurchased
        items[index].purchasedAt = purchasedAt
        sortItems()
    }

    func deleteItem(_ item: ShoppingItemModel) async throws {
        try await service.deleteItem(itemID: item.itemId, householdID: item.householdId)
        items.removeAll { $0.itemId == item.itemId }
    }

    func clearPurchasedItems() async throws {
        let purchasedItems = items.filter(\.isPurchased)
        try await service.deleteItems(purchasedItems)
        items.removeAll { $0.isPurchased }
    }

    func clearItems() {
        cancelObservations()
        activeItems = []
        purchasedItems = []
        items = []
    }

    private func mergeObservedItems() {
        let availablePurchasedSlots = max(0, 40 - activeItems.count)
        items = activeItems + Array(purchasedItems.prefix(availablePurchasedSlots))
        sortItems()
    }

    private func cancelObservations() {
        activeObservation?.cancel()
        purchasedObservation?.cancel()
        activeObservation = nil
        purchasedObservation = nil
    }

    private func sortItems() {
        items.sort { firstItem, secondItem in
            if firstItem.isPurchased != secondItem.isPurchased {
                return !firstItem.isPurchased
            }

            return (firstItem.createdAt ?? .distantPast) > (secondItem.createdAt ?? .distantPast)
        }
    }

    private func trimItems() {
        guard items.count > 40 else {
            return
        }

        let activeItems = items.filter { !$0.isPurchased }
        let purchasedItems = items.filter(\.isPurchased)
        let availablePurchasedSlots = max(0, 40 - activeItems.count)
        items = Array(activeItems.prefix(40)) + Array(purchasedItems.prefix(availablePurchasedSlots))
    }
}
