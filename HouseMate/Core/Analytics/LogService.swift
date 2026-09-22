import Foundation

@MainActor
protocol LogService {
    func identifyUser(userID: String)
    func addUserProperties(_ properties: [String: Any])
    func resetUser()
    func deleteUserProfile()
    func trackEvent(_ event: any LoggableEvent)
    func trackScreen(_ event: any LoggableEvent)
}

extension LogService {
    func trackScreen(_ event: any LoggableEvent) {
        trackEvent(event)
    }
}

@MainActor
struct CompositeLogService: LogService {
    let services: [any LogService]

    func identifyUser(userID: String) {
        services.forEach { $0.identifyUser(userID: userID) }
    }

    func addUserProperties(_ properties: [String: Any]) {
        services.forEach { $0.addUserProperties(properties) }
    }

    func resetUser() {
        services.forEach { $0.resetUser() }
    }

    func deleteUserProfile() {
        services.forEach { $0.deleteUserProfile() }
    }

    func trackEvent(_ event: any LoggableEvent) {
        services.forEach { $0.trackEvent(event) }
    }

    func trackScreen(_ event: any LoggableEvent) {
        services.forEach { $0.trackScreen(event) }
    }
}
