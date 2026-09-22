//
//  AppEnvironment.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import Foundation

enum AppEnvironment: String {

    case mock
    case development
    case production

    static var current: AppEnvironment {
#if MOCK
        return .mock
#elseif DEVELOPMENT
        return .development
#elseif PRODUCTION
        return .production
#else
        fatalError("No AppEnvironment compilation condition configured.")
#endif
    }

    var usesFirebase: Bool {
        self != .mock
    }

    var displayName: String {
        switch self {
        case .mock:
            return "HouseMate Mock"

        case .development:
            return "HouseMate Dev"

        case .production:
            return "HouseMate"
        }
    }

    var firebaseConfigurationFileName: String? {
        switch self {
        case .mock:
            return nil

        case .development:
            return "GoogleService-Info-Development"

        case .production:
            return "GoogleService-Info-Production"
        }
    }

    var mixpanelToken: String? {
        let key: String

        switch self {
        case .mock:
            return nil
        case .development:
            key = "MixpanelTokenDevelopment"
        case .production:
            key = "MixpanelTokenProduction"
        }

        guard let token = Bundle.main.object(
            forInfoDictionaryKey: key
        ) as? String else {
            return nil
        }

        let trimmedToken = token.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmedToken.isEmpty ? nil : trimmedToken
    }
}
