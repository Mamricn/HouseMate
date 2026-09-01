//
//  AuthServiceFactory.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import Foundation

@MainActor
enum AuthServiceFactory {

    static func make() -> any AuthServiceProtocol {
#if MOCK
        return MockAuthService()
#else
        return FirebaseAuthService()
#endif
    }
}
