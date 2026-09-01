//
//  UserServiceFactory.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import Foundation

@MainActor
enum UserServiceFactory {

    static func make() -> any UserServiceProtocol {
#if MOCK
        return MockUserService()
#else
        return FirebaseUserService()
#endif
    }
}
