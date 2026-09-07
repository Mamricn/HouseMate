import FirebaseFirestore
import FirebaseMessaging
import UIKit

@MainActor
final class FirebaseRemoteNotificationService:
    RemoteNotificationServiceProtocol {

    static let shared = FirebaseRemoteNotificationService()

    private let database: Firestore
    private var currentUser: UserModel?
    private var currentRegistrationID: String?

    private init(database: Firestore = .firestore()) {
        self.database = database
    }

    func registerDevice(for user: UserModel) async throws {
        currentUser = user
        UIApplication.shared.registerForRemoteNotifications()
        try await registerWithFCM()

        if let currentRegistrationID {
            try await save(
                registrationID: currentRegistrationID,
                for: user
            )
        }

        #if DEBUG
        print("Firebase Messaging registration requested.")
        #endif
    }

    func unregisterCurrentDevice(userID: String) async {
        if let currentRegistrationID {
            try? await registrationReference(
                registrationID: currentRegistrationID,
                userID: userID
            )
            .delete()
        }

        await unregisterFromFCM()
        currentUser = nil
        currentRegistrationID = nil
    }

    func receiveRegistrationID(_ registrationID: String) {
        currentRegistrationID = registrationID

        #if DEBUG
        print("Firebase registration ID received: \(registrationID)")
        #endif

        guard let currentUser else { return }

        Task {
            do {
                try await save(
                    registrationID: registrationID,
                    for: currentUser
                )
            } catch {
                #if DEBUG
                print(
                    "Saving Firebase registration failed: "
                    + error.localizedDescription
                )
                #endif
            }
        }
    }

    func updatePreferences() async throws {
        guard let currentUser,
              let currentRegistrationID else {
            return
        }

        try await save(
            registrationID: currentRegistrationID,
            for: currentUser
        )
    }

    private func save(
        registrationID: String,
        for user: UserModel
    ) async throws {
        var data: [String: Any] = [
            "registration_id": registrationID,
            "platform": "ios",
            "environment": AppEnvironment.current.rawValue,
            "task_notifications_enabled": preferenceEnabled(
                key: "taskNotificationsEnabled"
            ),
            "bill_notifications_enabled": preferenceEnabled(
                key: "billNotificationsEnabled"
            ),
            "house_reminder_notifications_enabled": preferenceEnabled(
                key: "houseReminderNotificationsEnabled"
            ),
            "time_zone_id": TimeZone.autoupdatingCurrent.identifier,
            "updated_at": FieldValue.serverTimestamp()
        ]

        if let householdID = user.householdId {
            data["household_id"] = householdID
        }

        try await registrationReference(
            registrationID: registrationID,
            userID: user.id
        )
            .setData(data, merge: true)

        #if DEBUG
        print("Firebase registration saved for user: \(user.id)")
        #endif
    }

    private func registrationReference(
        registrationID: String,
        userID: String
    ) -> DocumentReference {
        database
            .collection("users")
            .document(userID)
            .collection("device_tokens")
            .document(registrationID)
    }

    private func registerWithFCM() async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            Messaging.messaging().register { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func unregisterFromFCM() async {
        await withCheckedContinuation { continuation in
            Messaging.messaging().unregister { _ in
                continuation.resume()
            }
        }
    }

    private func preferenceEnabled(key: String) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil
            ? true
            : defaults.bool(forKey: key)
    }
}
