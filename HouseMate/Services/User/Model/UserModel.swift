//
//  UserModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import Foundation

struct UserModel: Identifiable, Codable, Equatable {
    
    var id: String { userId }
    
    let userId: String                 // Firebase Auth UID
    
    let createdAt: Date?
    let creationVersion: String?
    let email: String?
    let lastSignInDate: Date?
    
    var name: String?
    var profileImageUrl: String?
    
    var householdId: String?
    
    
    init(
        userId: String,
        createdAt: Date? = nil,
        creationVersion: String? = nil,
        email: String? = nil,
        lastSignInDate: Date? = nil,
        name: String? = nil,
        profileImageUrl: String? = nil,
        householdId: String? = nil
    ) {
        self.userId = userId
        self.createdAt = createdAt
        self.creationVersion = creationVersion
        self.email = email
        self.lastSignInDate = lastSignInDate
        self.name = name
        self.profileImageUrl = profileImageUrl
        self.householdId = householdId
    }
    
    
//    init(auth: UserAuthInfo, creationVersion: String?) {
//        self.init(
//            userId: auth.uid,
//            createdAt: auth.creationData,
//            creationVersion: creationVersion,
//            email: auth.email,
//            lastSignInDate: auth.lastSignInData,
//            name: nil,
//            profileImageUrl: nil,
//            householdId: nil
//        )
//    }
//    
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case createdAt = "created_at"
        case creationVersion = "creation_version"
        case email
        case lastSignInDate = "last_sign_in_date"
        case name
        case profileImageUrl = "profile_image_url"
        case householdId = "household_id"
    }
    
    
    var eventParameters: [String: Any] {
        
        let dict: [String: Any?] = [
            "user_\(CodingKeys.userId.rawValue)": userId,
            "user_\(CodingKeys.createdAt.rawValue)": createdAt,
            "user_\(CodingKeys.creationVersion.rawValue)": creationVersion,
            "user_\(CodingKeys.email.rawValue)": email,
            "user_\(CodingKeys.lastSignInDate.rawValue)": lastSignInDate,
            "user_\(CodingKeys.name.rawValue)": name,
            "user_\(CodingKeys.profileImageUrl.rawValue)": profileImageUrl,
            "user_\(CodingKeys.householdId.rawValue)": householdId
        ]
        
        return dict.compactMapValues { $0 }
    }
}
extension UserModel {
    
    static let mock = UserModel(
        userId: "123",
        createdAt: .now,
        creationVersion: "1.0",
        email: "marcin@email.com",
        lastSignInDate: .now,
        name: "Marcin",
        profileImageUrl: nil,
        householdId: "house_123"
    )
    
    
    static let mockNoHousehold = UserModel(
        userId: "456",
        createdAt: .now,
        creationVersion: "1.0",
        email: "adam@email.com",
        lastSignInDate: .now,
        name: "Adam",
        profileImageUrl: nil,
        householdId: nil
    )
    
    
    static let mockList: [UserModel] = [
        
        UserModel(
            userId: "1",
            createdAt: .now,
            email: "marcin@email.com",
            lastSignInDate: .now,
            name: "Marcin",
            householdId: "house_123"
        ),
        
        UserModel(
            userId: "2",
            createdAt: .now,
            email: "adam@email.com",
            lastSignInDate: .now,
            name: "Adam",
            householdId: "house_123"
        ),
        
        UserModel(
            userId: "3",
            createdAt: .now,
            email: "kamil@email.com",
            lastSignInDate: .now,
            name: "Kamil",
            householdId: "house_123"
        )
    ]
}
