import Foundation
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class FirebaseHouseholdDocumentService: HouseholdDocumentServiceProtocol {
    private let database: Firestore
    private let storage: Storage

    init(database: Firestore = .firestore(), storage: Storage = .storage()) {
        self.database = database
        self.storage = storage
    }

    func fetchDocuments(householdID: String, limit: Int) async throws -> [HouseholdDocumentModel] {
        let snapshot = try await collection(householdID)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try decode(snapshot.documents)
    }

    func observeDocuments(
        householdID: String,
        limit: Int,
        onChange: @escaping (Result<[HouseholdDocumentModel], Error>) -> Void
    ) -> ServiceObservation? {
        let listener = collection(householdID)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                do {
                    onChange(.success(try self.decode(snapshot?.documents ?? [])))
                } catch {
                    onChange(.failure(error))
                }
            }
        return ServiceObservation(cancellation: listener.remove)
    }

    func createDocument(
        _ document: HouseholdDocumentModel,
        attachment: DocumentAttachmentDraft
    ) async throws -> HouseholdDocumentModel {
        let safeName = attachment.fileName.replacingOccurrences(of: "/", with: "-")
        let path = "household_documents/\(document.householdId)/\(document.documentId)/\(safeName)"
        let reference = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = attachment.contentType

        _ = try await reference.putDataAsync(attachment.data, metadata: metadata)

        do {
            let url = try await reference.downloadURL()
            var saved = document
            saved.fileName = safeName
            saved.fileURL = url.absoluteString
            saved.storagePath = path
            saved.contentType = attachment.contentType
            let data = try Firestore.Encoder().encode(saved)
            try await collection(saved.householdId).document(saved.documentId).setData(data)
            return saved
        } catch {
            try? await reference.delete()
            throw error
        }
    }

    func updateDocument(_ document: HouseholdDocumentModel) async throws {
        let data = try Firestore.Encoder().encode(document)
        try await collection(document.householdId)
            .document(document.documentId)
            .setData(data)
    }

    func deleteDocument(_ document: HouseholdDocumentModel) async throws {
        try await collection(document.householdId).document(document.documentId).delete()
        if !document.storagePath.isEmpty {
            try? await storage.reference().child(document.storagePath).delete()
        }
    }

    private func collection(_ householdID: String) -> CollectionReference {
        database.collection("households").document(householdID).collection("documents")
    }

    private func decode(_ documents: [QueryDocumentSnapshot]) throws -> [HouseholdDocumentModel] {
        try documents.map { try Firestore.Decoder().decode(HouseholdDocumentModel.self, from: $0.data()) }
    }
}
