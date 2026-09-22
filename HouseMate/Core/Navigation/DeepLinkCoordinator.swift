import Foundation
import Observation

enum AppDeepLink: Equatable {
    case joinHousehold(inviteCode: String)
    case notification(
        destination: NotificationDestination,
        householdID: String?,
        entityID: String?
    )
}

@MainActor
@Observable
final class DeepLinkCoordinator {

    static let shared = DeepLinkCoordinator()

    private(set) var pending: AppDeepLink?

    private init() {}

    func handle(url: URL) {
        guard let deepLink = Self.deepLink(from: url) else { return }
        pending = deepLink
    }

    func handle(notificationUserInfo: [AnyHashable: Any]) {
        let payloadType = (notificationUserInfo["type"] as? String)
            .flatMap(NotificationType.init(rawValue:))
        let payloadDestination = (notificationUserInfo["destination"] as? String)
            .flatMap(NotificationDestination.init(rawValue:))

        // Prefer the semantic notification type. It repairs routing for older
        // payloads that used the generic `household`/`housemates` destination.
        guard let destination = payloadType?.defaultDestination
                ?? payloadDestination else {
            return
        }

        pending = .notification(
            destination: destination,
            householdID: notificationUserInfo["household_id"] as? String
                ?? notificationUserInfo["householdId"] as? String,
            entityID: notificationUserInfo["entity_id"] as? String
                ?? notificationUserInfo["related_entity_id"] as? String
                ?? notificationUserInfo["relatedEntityId"] as? String
                ?? notificationUserInfo["poll_id"] as? String
                ?? notificationUserInfo["task_id"] as? String
                ?? notificationUserInfo["bill_id"] as? String
                ?? notificationUserInfo["reminder_id"] as? String
        )
    }

    func consume(_ deepLink: AppDeepLink) {
        guard pending == deepLink else { return }
        pending = nil
    }

    private static func deepLink(from url: URL) -> AppDeepLink? {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let isCustomScheme = url.scheme?.lowercased() == "housemate"

        let inviteCode: String?
        if isCustomScheme,
           url.host?.lowercased() == "join" {
            inviteCode = pathComponents.first
        } else if let joinIndex = pathComponents.firstIndex(
            where: { $0.lowercased() == "join" }
        ), pathComponents.indices.contains(joinIndex + 1) {
            // This also supports the future Universal Link:
            // https://<configured-domain>/join/ABC123
            inviteCode = pathComponents[joinIndex + 1]
        } else {
            inviteCode = nil
        }

        guard let inviteCode else { return nil }
        let normalizedCode = inviteCode
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }

        guard normalizedCode.count == 6 else { return nil }
        return .joinHousehold(inviteCode: normalizedCode)
    }
}
