import Foundation

@MainActor
protocol HouseholdDocumentServiceProtocol: AnyObject {
    func fetchDocuments(householdID: String, limit: Int) async throws -> [HouseholdDocumentModel]
    func observeDocuments(
        householdID: String,
        limit: Int,
        onChange: @escaping (Result<[HouseholdDocumentModel], Error>) -> Void
    ) -> ServiceObservation?
    func createDocument(
        _ document: HouseholdDocumentModel,
        attachment: DocumentAttachmentDraft
    ) async throws -> HouseholdDocumentModel
    func updateDocument(_ document: HouseholdDocumentModel) async throws
    func deleteDocument(_ document: HouseholdDocumentModel) async throws
}

extension HouseholdDocumentServiceProtocol {
    func observeDocuments(
        householdID: String,
        limit: Int,
        onChange: @escaping (Result<[HouseholdDocumentModel], Error>) -> Void
    ) -> ServiceObservation? { nil }
}
