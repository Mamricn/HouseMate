import Foundation

@MainActor
protocol RemoteNotificationServiceProtocol: AnyObject {
    func registerDevice(for user: UserModel) async throws
    func unregisterCurrentDevice(userID: String) async
    func receiveRegistrationID(_ registrationID: String)
    func updatePreferences() async throws
}
