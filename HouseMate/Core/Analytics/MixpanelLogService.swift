import Foundation
import Mixpanel

@MainActor
struct MixpanelLogService: LogService {
    private let flushesImmediately: Bool

    private var instance: MixpanelInstance {
        Mixpanel.mainInstance()
    }

    init(
        token: String,
        loggingEnabled: Bool = false,
        flushesImmediately: Bool = false
    ) {
        self.flushesImmediately = flushesImmediately
        Mixpanel.initialize(
            token: token,
            trackAutomaticEvents: false,
            serverURL: "https://api-eu.mixpanel.com"
        )
        Mixpanel.mainInstance().loggingEnabled = loggingEnabled
    }

    func identifyUser(userID: String) {
        instance.identify(distinctId: userID)
    }

    func addUserProperties(_ properties: [String: Any]) {
        let safeProperties = mixpanelProperties(from: properties)
        guard !safeProperties.isEmpty else { return }
        instance.people.set(properties: safeProperties)
    }

    func resetUser() {
        instance.reset()
    }

    func deleteUserProfile() {
        instance.people.deleteUser()
        instance.reset()
    }

    func trackEvent(_ event: any LoggableEvent) {
        guard event.type != .info else { return }

        let properties = mixpanelProperties(from: event.parameters ?? [:])
        instance.track(
            event: event.eventName,
            properties: properties.isEmpty ? nil : properties
        )

        if flushesImmediately {
            instance.flush()
        }
    }

    private func mixpanelProperties(
        from properties: [String: Any]
    ) -> Properties {
        var result: Properties = [:]

        for (rawKey, value) in properties {
            let key = String(rawKey.prefix(255))
            if let value = value as? MixpanelType {
                result[key] = value
            }
        }

        return result
    }
}
