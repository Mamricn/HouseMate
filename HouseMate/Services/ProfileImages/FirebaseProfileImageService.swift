import Foundation
import FirebaseStorage

@MainActor
final class FirebaseProfileImageService: ProfileImageServiceProtocol {

    private let storage: Storage

    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    func uploadProfileImage(
        _ data: Data,
        userID: String
    ) async throws -> URL {
        let fileName = "avatar-\(UUID().uuidString).jpg"
        let reference = storage.reference()
            .child("profile_images")
            .child(userID)
            .child(fileName)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public,max-age=31536000,immutable"

        _ = try await reference.putDataAsync(
            data,
            metadata: metadata
        )

        return try await reference.downloadURL()
    }

    func deleteProfileImage(at url: URL) async throws {
        try await storage.reference(forURL: url.absoluteString).delete()
    }
}
