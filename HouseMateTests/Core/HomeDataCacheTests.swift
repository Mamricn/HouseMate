import Foundation
import Testing
@testable import HouseMate

@Suite("Home data cache")
struct HomeDataCacheTests {

    @Test("Cache keeps data from different households separated")
    @MainActor
    func keepsHouseholdsSeparated() throws {
        let suiteName = "HomeDataCacheTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = makeTask(id: "first", householdID: "home-a")
        let second = makeTask(id: "second", householdID: "home-b")

        HomeDataCache.save([first], feature: .tasks, householdID: "home-a", defaults: defaults)
        HomeDataCache.save([second], feature: .tasks, householdID: "home-b", defaults: defaults)

        let firstResult: [TaskModel]? = HomeDataCache.load(
            feature: .tasks,
            householdID: "home-a",
            defaults: defaults
        )
        let secondResult: [TaskModel]? = HomeDataCache.load(
            feature: .tasks,
            householdID: "home-b",
            defaults: defaults
        )

        #expect(firstResult == [first])
        #expect(secondResult == [second])
    }

    @Test("Cache rejects entries older than its maximum age")
    @MainActor
    func rejectsExpiredEntry() throws {
        let suiteName = "HomeDataCacheTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let savedAt = Date(timeIntervalSince1970: 1_000)
        HomeDataCache.save(
            [makeTask(id: "expired", householdID: "home")],
            feature: .tasks,
            householdID: "home",
            defaults: defaults,
            now: savedAt
        )

        let result: [TaskModel]? = HomeDataCache.load(
            feature: .tasks,
            householdID: "home",
            defaults: defaults,
            now: savedAt.addingTimeInterval(8 * 24 * 60 * 60)
        )

        #expect(result == nil)
    }
}
