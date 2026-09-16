import Foundation

@MainActor
final class MockHouseholdDocumentService: HouseholdDocumentServiceProtocol {
    private var documents = HouseholdDocumentModel.mockList

    func fetchDocuments(householdID: String, limit: Int) async throws -> [HouseholdDocumentModel] {
        Array(documents.filter { $0.householdId == householdID }.prefix(limit))
    }

    func createDocument(
        _ document: HouseholdDocumentModel,
        attachment: DocumentAttachmentDraft
    ) async throws -> HouseholdDocumentModel {
        var saved = document
        saved.fileName = attachment.fileName
        saved.contentType = attachment.contentType
        documents.insert(saved, at: 0)
        return saved
    }

    func updateDocument(_ document: HouseholdDocumentModel) async throws {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index] = document
    }

    func deleteDocument(_ document: HouseholdDocumentModel) async throws {
        documents.removeAll { $0.id == document.id }
    }
}
