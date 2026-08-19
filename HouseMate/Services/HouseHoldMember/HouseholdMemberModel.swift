//
//  HouseholdMemberModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


//
//  HouseholdMemberModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import Foundation

struct HouseholdMemberModel: Identifiable, Codable, Equatable {
    
    var id: String { memberId }
    
    let memberId: String
    let householdId: String
    let userId: String
    
    let joinedAt: Date?
    
    var displayName: String
    var profileImageUrl: String?
    
    
    init(
        memberId: String,
        householdId: String,
        userId: String,
        joinedAt: Date? = nil,
        displayName: String,
        profileImageUrl: String? = nil
    ) {
        self.memberId = memberId
        self.householdId = householdId
        self.userId = userId
        self.joinedAt = joinedAt
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
    }
    
    
    enum CodingKeys: String, CodingKey {
        case memberId = "member_id"
        case householdId = "household_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case displayName = "display_name"
        case profileImageUrl = "profile_image_url"
    }
    
    
    var eventParameters: [String: Any] {
        
        let dict: [String: Any?] = [
            "member_\(CodingKeys.memberId.rawValue)": memberId,
            "member_\(CodingKeys.householdId.rawValue)": householdId,
            "member_\(CodingKeys.userId.rawValue)": userId,
            "member_\(CodingKeys.joinedAt.rawValue)": joinedAt,
            "member_\(CodingKeys.displayName.rawValue)": displayName,
            "member_\(CodingKeys.profileImageUrl.rawValue)": profileImageUrl
        ]
        
        return dict.compactMapValues { $0 }
    }
}
extension HouseholdMemberModel {
    
    static let mock = HouseholdMemberModel(
        memberId: "member_1",
        householdId: "house_123",
        userId: "user_1",
        joinedAt: .now,
        displayName: "Marcin"
    )
    
    
    static let mockList: [HouseholdMemberModel] = [
        HouseholdMemberModel(
            memberId: "member_1",
            householdId: "house_123",
            userId: "1",
            joinedAt: .now,
            displayName: "Marcin"
        ),
        
        HouseholdMemberModel(
            memberId: "member_2",
            householdId: "house_123",
            userId: "2",
            joinedAt: .now,
            displayName: "Adam"
        ),
        
        HouseholdMemberModel(
            memberId: "member_3",
            householdId: "house_123",
            userId: "3",
            joinedAt: .now,
            displayName: "Kamil"
        )
    ]
}
