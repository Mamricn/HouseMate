//
//  ShoppingItemModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


import Foundation

struct ShoppingItemModel: Identifiable, Codable, Equatable {
    
    var id: String { itemId }
    
    let itemId: String
    let householdId: String
    let createdAt: Date?
    
    var name: String
    var quantity: Int
    var addedByUserId: String
    var isPurchased: Bool
    
    
    init(
        itemId: String,
        householdId: String,
        createdAt: Date? = nil,
        name: String,
        quantity: Int = 1,
        addedByUserId: String,
        isPurchased: Bool = false
    ) {
        self.itemId = itemId
        self.householdId = householdId
        self.createdAt = createdAt
        self.name = name
        self.quantity = quantity
        self.addedByUserId = addedByUserId
        self.isPurchased = isPurchased
    }
    
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case name
        case quantity
        case addedByUserId = "added_by_user_id"
        case isPurchased = "is_purchased"
    }
    
    
    var eventParameters: [String: Any] {
        
        let dict: [String: Any?] = [
            "shopping_\(CodingKeys.itemId.rawValue)": itemId,
            "shopping_\(CodingKeys.householdId.rawValue)": householdId,
            "shopping_\(CodingKeys.createdAt.rawValue)": createdAt,
            "shopping_\(CodingKeys.name.rawValue)": name,
            "shopping_\(CodingKeys.quantity.rawValue)": quantity,
            "shopping_\(CodingKeys.addedByUserId.rawValue)": addedByUserId,
            "shopping_\(CodingKeys.isPurchased.rawValue)": isPurchased
        ]
        
        return dict.compactMapValues { $0 }
    }
}



extension ShoppingItemModel {
    
    static let mock = ShoppingItemModel(
        itemId: "item_1",
        householdId: "house_123",
        createdAt: .now,
        name: "Milk",
        quantity: 2,
        addedByUserId: "user_1"
    )
    
    
    static let mockList: [ShoppingItemModel] = [
        ShoppingItemModel(
            itemId: "item_1",
            householdId: "house_123",
            createdAt: .now,
            name: "Milk",
            quantity: 2,
            addedByUserId: "user_1"
        ),
        
        ShoppingItemModel(
            itemId: "item_2",
            householdId: "house_123",
            createdAt: .now,
            name: "Eggs",
            quantity: 12,
            addedByUserId: "user_2",
            isPurchased: true
        )
    ]
}
