import Foundation
import OSLog

@MainActor
struct ConsoleLogService: LogService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "HouseMate",
        category: "Analytics"
    )
    private let printsParameters: Bool

    init(printsParameters: Bool = true) {
        self.printsParameters = printsParameters
    }

    func identifyUser(userID: String) {
        logger.info("📈 Identify user: \(userID, privacy: .private(mask: .hash))")
    }

    func addUserProperties(_ properties: [String: Any]) {
        log(name: "User properties", type: .info, parameters: properties)
    }

    func resetUser() {
        logger.info("📈 Reset analytics identity")
    }

    func deleteUserProfile() {
        logger.info("📈 Delete analytics user profile")
    }

    func trackEvent(_ event: any LoggableEvent) {
        log(name: event.eventName, type: event.type, parameters: event.parameters)
    }

    private func log(
        name: String,
        type: LogType,
        parameters: [String: Any]?
    ) {
        var message = "\(type.emoji) \(name)"

        if printsParameters, let parameters, !parameters.isEmpty {
            let values = parameters.keys.sorted().map { key in
                "\(key)=\(String(describing: parameters[key]!))"
            }
            message += " | " + values.joined(separator: ", ")
        }

        switch type {
        case .info:
            logger.info("\(message, privacy: .public)")
        case .analytic:
            logger.notice("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .severe:
            logger.fault("\(message, privacy: .public)")
        }
    }
}
