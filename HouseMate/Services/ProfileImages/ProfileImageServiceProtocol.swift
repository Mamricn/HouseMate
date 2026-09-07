import Foundation

@MainActor
protocol ProfileImageServiceProtocol: AnyObject {
    func uploadProfileImage(
        _ data: Data,
        userID: String
    ) async throws -> URL

    func deleteProfileImage(at url: URL) async throws
}

enum ProfileImageError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        "The selected image could not be processed."
    }
}
