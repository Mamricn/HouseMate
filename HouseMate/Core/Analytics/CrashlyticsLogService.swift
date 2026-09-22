import Foundation
import FirebaseCrashlytics

@MainActor
struct CrashlyticsLogService: LogService {
    private let crashlytics = Crashlytics.crashlytics()

    init(environment: AppEnvironment) {
        crashlytics.setCustomValue(
            environment.rawValue,
            forKey: "environment"
        )
    }

    func identifyUser(userID: String) {
        crashlytics.setUserID(userID)
    }

    func addUserProperties(_ properties: [String: Any]) {
        if let environment = properties["environment"] as? String {
            crashlytics.setCustomValue(
                environment,
                forKey: "environment"
            )
        }
    }

    func resetUser() {
        crashlytics.setUserID("")
    }

    func deleteUserProfile() {
        resetUser()
    }

    func trackEvent(_ event: any LoggableEvent) {
        guard event.type == .severe else { return }

        crashlytics.log("Non-fatal event: \(event.eventName)")

        let parameters = event.parameters ?? [:]
        let error = NSError(
            domain: parameters["error_domain"] as? String
                ?? "HouseMate.NonFatal",
            code: parameters["error_code"] as? Int ?? 0,
            userInfo: [
                "event_name": event.eventName,
                "error_type": parameters["error_type"] as? String
                    ?? "UnknownError"
            ]
        )

        crashlytics.record(error: error)
    }
}
