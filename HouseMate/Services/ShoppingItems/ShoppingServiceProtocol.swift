//
//  ShoppingServiceProtocol.swift
//  HouseMate
//

import Foundation

@MainActor
protocol ShoppingServiceProtocol: AnyObject {
    func fetchLists(householdID: String) async throws -> [ShoppingCollection]
    func observeLists(householdID: String, onChange: @escaping (Result<[ShoppingCollection], Error>) -> Void) -> ServiceObservation?
    func saveList(_ list: ShoppingCollection, householdID: String) async throws
    func moveItem(_ item: ShoppingItemModel, to listID: String) async throws

    func fetchActiveItems(householdID: String, limit: Int) async throws -> [ShoppingItemModel]

    func fetchRecentlyPurchasedItems(householdID: String, purchasedAfter date: Date, limit: Int) async throws -> [ShoppingItemModel]

    func observeActiveItems(householdID: String, limit: Int, onChange: @escaping (Result<[ShoppingItemModel], Error>) -> Void) -> ServiceObservation?

    func observeRecentlyPurchasedItems(householdID: String, purchasedAfter date: Date, limit: Int, onChange: @escaping (Result<[ShoppingItemModel], Error>) -> Void) -> ServiceObservation?

    func createItem(_ item: ShoppingItemModel) async throws

    func updatePurchasedState(itemID: String, householdID: String, isPurchased: Bool, purchasedAt: Date?) async throws

    func deleteItem(itemID: String, householdID: String) async throws

    func deleteItems(_ items: [ShoppingItemModel]) async throws
}

extension ShoppingServiceProtocol {
    func observeLists(householdID: String, onChange: @escaping (Result<[ShoppingCollection], Error>) -> Void) -> ServiceObservation? { nil }

    func observeActiveItems(householdID: String, limit: Int, onChange: @escaping (Result<[ShoppingItemModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }

    func observeRecentlyPurchasedItems(householdID: String, purchasedAfter date: Date, limit: Int, onChange: @escaping (Result<[ShoppingItemModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }
}
