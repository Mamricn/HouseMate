//
//  HomeDataCache.swift
//  HouseMate
//

import Foundation

@MainActor
enum HomeDataCache {

    enum Feature: String {
        case tasks
        case shoppingItems
        case shoppingLists
        case bills
        case reminders
    }

    private struct Entry<Value: Codable>: Codable {
        let savedAt: Date
        let value: Value
    }

    private static let version = "v1"
    private static let maximumAge: TimeInterval = 7 * 24 * 60 * 60

    static func load<Value: Codable>(
        _ type: Value.Type = Value.self,
        feature: Feature,
        householdID: String,
        defaults: UserDefaults = .standard,
        now: Date = .now
    ) -> Value? {
        let cacheKey = key(feature: feature, householdID: householdID)

        guard let data = defaults.data(forKey: cacheKey),
              let entry = try? JSONDecoder().decode(Entry<Value>.self, from: data),
              now.timeIntervalSince(entry.savedAt) <= maximumAge else {
            defaults.removeObject(forKey: cacheKey)
            return nil
        }

        return entry.value
    }

    static func save<Value: Codable>(
        _ value: Value,
        feature: Feature,
        householdID: String,
        defaults: UserDefaults = .standard,
        now: Date = .now
    ) {
        let entry = Entry(savedAt: now, value: value)
        guard let data = try? JSONEncoder().encode(entry) else { return }

        defaults.set(
            data,
            forKey: key(feature: feature, householdID: householdID)
        )
    }

    private static func key(
        feature: Feature,
        householdID: String
    ) -> String {
        "housemate.home-cache.\(version).\(feature.rawValue).\(householdID)"
    }
}
