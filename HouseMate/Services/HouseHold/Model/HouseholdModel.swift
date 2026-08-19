//
//  HouseholdModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


//
//  HouseholdModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import Foundation

struct HouseholdModel: Identifiable, Codable, Equatable {
    
    var id: String { householdId }
    
    let householdId: String
    let createdAt: Date?
    
    var name: String
    var inviteCode: String
    
    var createdByUserId: String
    var memberIds: [String]
    
    
    init(
        householdId: String,
        createdAt: Date? = nil,
        name: String,
        inviteCode: String,
        createdByUserId: String,
        memberIds: [String] = []
    ) {
        self.householdId = householdId
        self.createdAt = createdAt
        self.name = name
        self.inviteCode = inviteCode
        self.createdByUserId = createdByUserId
        self.memberIds = memberIds
    }
    
    
    enum CodingKeys: String, CodingKey {
        case householdId = "household_id"
        case createdAt = "created_at"
        case name
        case inviteCode = "invite_code"
        case createdByUserId = "created_by_user_id"
        case memberIds = "member_ids"
    }
    
    
    var eventParameters: [String: Any] {
        
        let dict: [String: Any?] = [
            "household_\(CodingKeys.householdId.rawValue)": householdId,
            "household_\(CodingKeys.createdAt.rawValue)": createdAt,
            "household_\(CodingKeys.name.rawValue)": name,
            "household_\(CodingKeys.inviteCode.rawValue)": inviteCode,
            "household_\(CodingKeys.createdByUserId.rawValue)": createdByUserId,
            "household_\(CodingKeys.memberIds.rawValue)": memberIds
        ]
        
        return dict.compactMapValues { $0 }
    }
}
extension HouseholdModel {
    
    static let mock = HouseholdModel(
        householdId: "house_123",
        createdAt: .now,
        name: "Our Home",
        inviteCode: "A7K9P2",
        createdByUserId: "1",
        memberIds: [
            "1",
            "2",
            "3"
        ]
    )
    
    
    static let mockEmpty = HouseholdModel(
        householdId: "house_456",
        createdAt: .now,
        name: "London Flat",
        inviteCode: "X8M4KL",
        createdByUserId: "1",
        memberIds: [
            "1"
        ]
    )
}
