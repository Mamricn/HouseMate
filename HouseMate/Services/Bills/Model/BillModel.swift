//
//  BillModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


import Foundation

struct BillModel: Identifiable, Codable, Equatable {
    
    var id: String { billId }
    
    let billId: String
    let householdId: String
    let createdAt: Date?
    
    var title: String
    var amount: Double
    var dueDate: Date?
    var category: BillCategory
    
    var createdByUserId: String
    var paidByUserId: String?
    var paidAt: Date?
    
    var status: BillStatus
    
    var isRecurring: Bool
    var recurrence: BillRecurrence?
    var recurrenceSeriesId: String?
    var notificationAdvance: HouseReminderAdvance?
    
    
    init(
        billId: String,
        householdId: String,
        createdAt: Date? = nil,
        title: String,
        amount: Double,
        dueDate: Date? = nil,
        category: BillCategory = .other,
        createdByUserId: String,
        paidByUserId: String? = nil,
        paidAt: Date? = nil,
        status: BillStatus = .upcoming,
        isRecurring: Bool = false,
        recurrence: BillRecurrence? = nil,
        recurrenceSeriesId: String? = nil,
        notificationAdvance: HouseReminderAdvance? = nil
    ) {
        self.billId = billId
        self.householdId = householdId
        self.createdAt = createdAt
        self.title = title
        self.amount = amount
        self.dueDate = dueDate
        self.category = category
        self.createdByUserId = createdByUserId
        self.paidByUserId = paidByUserId
        self.paidAt = paidAt
        self.status = status
        self.isRecurring = isRecurring
        self.recurrence = recurrence
        self.recurrenceSeriesId = recurrenceSeriesId
        self.notificationAdvance = notificationAdvance
    }
    
    
    enum CodingKeys: String, CodingKey {
        case billId = "bill_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case title
        case amount
        case dueDate = "due_date"
        case category
        case createdByUserId = "created_by_user_id"
        case paidByUserId = "paid_by_user_id"
        case paidAt = "paid_at"
        case status
        case isRecurring = "is_recurring"
        case recurrence
        case recurrenceSeriesId = "recurrence_series_id"
        case notificationAdvance = "notification_advance"
    }
    
    
    var eventParameters: [String: Any] {
        
        let dict: [String: Any?] = [
            "bill_\(CodingKeys.billId.rawValue)": billId,
            "bill_\(CodingKeys.householdId.rawValue)": householdId,
            "bill_\(CodingKeys.createdAt.rawValue)": createdAt,
            "bill_\(CodingKeys.title.rawValue)": title,
            "bill_\(CodingKeys.amount.rawValue)": amount,
            "bill_\(CodingKeys.dueDate.rawValue)": dueDate,
            "bill_\(CodingKeys.category.rawValue)": category.rawValue,
            "bill_\(CodingKeys.createdByUserId.rawValue)": createdByUserId,
            "bill_\(CodingKeys.paidByUserId.rawValue)": paidByUserId,
            "bill_\(CodingKeys.paidAt.rawValue)": paidAt,
            "bill_\(CodingKeys.status.rawValue)": status.rawValue,
            "bill_\(CodingKeys.isRecurring.rawValue)": isRecurring,
            "bill_\(CodingKeys.recurrence.rawValue)": recurrence?.rawValue,
            "bill_\(CodingKeys.recurrenceSeriesId.rawValue)": recurrenceSeriesId,
            "bill_\(CodingKeys.notificationAdvance.rawValue)": notificationAdvance?.rawValue
        ]
        
        return dict.compactMapValues { $0 }
    }
}


// MARK: - Bill Category

enum BillCategory: String, Codable, CaseIterable {
    case electricity
    case water
    case internet
    case rent
    case gas
    case councilTax
    case subscription
    case other
    
    var systemImage: String {
        switch self {
        case .electricity:
            return "bolt.fill"
            
        case .water:
            return "drop.fill"
            
        case .internet:
            return "wifi"
            
        case .rent:
            return "house.fill"
            
        case .gas:
            return "flame.fill"
            
        case .councilTax:
            return "building.columns.fill"
            
        case .subscription:
            return "creditcard.fill"
            
        case .other:
            return "doc.text.fill"
        }
    }
}


// MARK: - Bill Status

enum BillStatus: String, Codable, CaseIterable {
    case upcoming
    case paid
    case overdue
}


// MARK: - Bill Recurrence

enum BillRecurrence: String, Codable, CaseIterable {
    case weekly
    case monthly
    case yearly
}


// MARK: - Mock Data

extension BillModel {
    
    static let mock = BillModel(
        billId: "bill_1",
        householdId: "house_123",
        createdAt: .now,
        title: "Electricity",
        amount: 84.50,
        dueDate: .now,
        category: .electricity,
        createdByUserId: "user_1",
        status: .upcoming,
        isRecurring: true,
        recurrence: .monthly
    )
    
    
    static let mockList: [BillModel] = [
        
        BillModel(
            billId: "bill_1",
            householdId: "house_123",
            createdAt: .now,
            title: "Electricity",
            amount: 84.50,
            dueDate: .now,
            category: .electricity,
            createdByUserId: "user_1",
            isRecurring: true,
            recurrence: .monthly
        ),
        
        BillModel(
            billId: "bill_2",
            householdId: "house_123",
            createdAt: .now,
            title: "Internet",
            amount: 35.00,
            dueDate: .now,
            category: .internet,
            createdByUserId: "user_2",
            isRecurring: true,
            recurrence: .monthly
        ),
        
        BillModel(
            billId: "bill_3",
            householdId: "house_123",
            createdAt: .now,
            title: "Rent",
            amount: 850,
            dueDate: .now,
            category: .rent,
            createdByUserId: "user_1",
            isRecurring: true,
            recurrence: .monthly
        )
    ]
}
