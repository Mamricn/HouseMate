//
//  BoardPostModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import Foundation

struct BoardPostModel: Identifiable, Codable, Equatable {
    
    var id: String { postId }
    
    let postId: String
    let householdId: String
    
    let createdAt: Date?
    
    let createdByUserId: String
    
    var text: String
    
    var imageUrl: String?
    
    
    init(
        postId: String,
        householdId: String,
        createdAt: Date? = nil,
        createdByUserId: String,
        text: String,
        imageUrl: String? = nil
    ) {
        self.postId = postId
        self.householdId = householdId
        self.createdAt = createdAt
        self.createdByUserId = createdByUserId
        self.text = text
        self.imageUrl = imageUrl
    }
    
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case createdByUserId = "created_by_user_id"
        case text
        case imageUrl = "image_url"
    }
    
    
    var eventParameters: [String: Any] {
        
        let dict: [String: Any?] = [
            "board_post_\(CodingKeys.postId.rawValue)": postId,
            "board_post_\(CodingKeys.householdId.rawValue)": householdId,
            "board_post_\(CodingKeys.createdAt.rawValue)": createdAt,
            "board_post_\(CodingKeys.createdByUserId.rawValue)": createdByUserId,
            "board_post_\(CodingKeys.text.rawValue)": text,
            "board_post_\(CodingKeys.imageUrl.rawValue)": imageUrl
        ]
        
        return dict.compactMapValues { $0 }
    }
}


extension BoardPostModel {
    
    static let mock = BoardPostModel(
        postId: "post_1",
        householdId: "house_123",
        createdAt: .now,
        createdByUserId: "1",
        text: "Anyone wants to order food tonight?"
    )
    
    
    static let mockList: [BoardPostModel] = [
        BoardPostModel(
            postId: "post_1",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "1",
            text: "Anyone wants to order food tonight?"
        ),
        
        BoardPostModel(
            postId: "post_2",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "2",
            text: "I’ll be home around 7pm."
        )
    ]
}
