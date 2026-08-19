//
//  UserAuthInfo.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


//
//  UserAuthInfo.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

//import Foundation
//import FirebaseAuth
//
//struct UserAuthInfo: Equatable {
//    
//    let uid: String
//    let email: String?
//    let creationData: Date?
//    let lastSignInData: Date?
//    
//    
//    init(
//        uid: String,
//        email: String? = nil,
//        creationData: Date? = nil,
//        lastSignInData: Date? = nil
//    ) {
//        self.uid = uid
//        self.email = email
//        self.creationData = creationData
//        self.lastSignInData = lastSignInData
//    }
//    
//    
//    init(user: User) {
//        self.init(
//            uid: user.uid,
//            email: user.email,
//            creationData: user.metadata.creationDate,
//            lastSignInData: user.metadata.lastSignInDate
//        )
//    }
//}
//
//
//extension UserAuthInfo {
//    
//    static let mock = UserAuthInfo(
//        uid: "123",
//        email: "marcin@email.com",
//        creationData: .now,
//        lastSignInData: .now
//    )
//}
