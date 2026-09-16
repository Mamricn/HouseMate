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
    private var listsObservation: ServiceObservation?
    private(set) var lists: [ShoppingCollection] = [.groceries]

    func saveList(_ list: ShoppingCollection, householdID: String) async throws {
        try await service.saveList(list, householdID: householdID)
        lists.removeAll { $0.id == list.id }
        lists.append(list)
    }

    func moveItem(_ item: ShoppingItemModel, to listID: String) async throws {
        var updated = item
        updated.listId = listID
        try await service.moveItem(item, to: listID)
        if let index = items.firstIndex(where: { $0.id == item.id }) { items[index] = updated }
    }
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
        let savedLists = try await service.fetchLists(householdID: householdID)
        mergeLists(savedLists)
        listsObservation = service.observeLists(householdID: householdID) { [weak self] result in
            if case .success(let lists) = result { self?.mergeLists(lists) }
        }

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

    func clearPurchasedItems(listID: String? = nil) async throws {
        let purchasedItems = items.filter { $0.isPurchased && (listID == nil || $0.shoppingListID == listID) }
        try await service.deleteItems(purchasedItems)
        let ids = Set(purchasedItems.map(\.id))
        items.removeAll { ids.contains($0.id) }
    }

    func clearItems() {
        cancelObservations()
        activeItems = []
        purchasedItems = []
        items = []
        lists = [.groceries]
    }

    private func mergeObservedItems() {
        let availablePurchasedSlots = max(0, 40 - activeItems.count)
        items = activeItems + Array(purchasedItems.prefix(availablePurchasedSlots))
        sortItems()
    }

    private func cancelObservations() {
        listsObservation?.cancel()
        listsObservation = nil
        activeObservation?.cancel()
        purchasedObservation?.cancel()
        activeObservation = nil
        purchasedObservation = nil
    }

    private func mergeLists(_ saved: [ShoppingCollection]) {
        lists = [.groceries] + saved.filter { $0.id != "groceries" }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        if let groceries = saved.first(where: { $0.id == "groceries" }) { lists[0] = groceries }
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
