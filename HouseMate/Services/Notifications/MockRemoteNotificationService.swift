import Foundation

@MainActor
final class MockRemoteNotificationService:
    RemoteNotificationServiceProtocol {

    func registerDevice(for user: UserModel) async throws {}
    func unregisterCurrentDevice(userID: String) async {}
    func receiveRegistrationID(_ registrationID: String) {}
    func updatePreferences() async throws {}
}
