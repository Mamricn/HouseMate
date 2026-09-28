import Foundation
import Testing
@testable import HouseMate

@Suite("ShoppingManager")
struct ShoppingManagerTests {

    @Test("Create, move, purchase and clear update the shopping list")
    @MainActor
    func managesShoppingItemLifecycle() async throws {
        let householdID = "shopping-\(UUID().uuidString)"
        let manager = ShoppingManager(service: MockShoppingService(items: []))
        try await manager.fetchItems(householdID: householdID)
        let item = ShoppingItemModel(
            itemId: "milk",
            householdId: householdID,
            createdAt: .now,
            name: "Milk",
            addedByUserId: "user"
        )

        try await manager.createItem(item)
        #expect(manager.items.count == 1)

        try await manager.moveItem(item, to: "weekly")
        #expect(manager.items.first?.shoppingListID == "weekly")

        let movedItem = try #require(manager.items.first)
        try await manager.togglePurchased(movedItem)
        #expect(manager.items.first?.isPurchased == true)

        try await manager.clearPurchasedItems(listID: "weekly")
        #expect(manager.items.isEmpty)
    }
}
