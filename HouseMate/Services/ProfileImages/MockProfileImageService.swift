import Foundation

@MainActor
final class MockProfileImageService: ProfileImageServiceProtocol {

    func uploadProfileImage(
        _ data: Data,
        userID: String
    ) async throws -> URL {
        guard !data.isEmpty,
              let url = URL(
                string: "https://example.com/profile_images/\(userID)/avatar-\(UUID().uuidString).jpg"
              )
        else {
            throw ProfileImageError.invalidImage
        }

        return url
    }

    func deleteProfileImage(at url: URL) async throws {}
}
