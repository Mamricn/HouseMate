import Foundation

@Observable
@MainActor
final class HouseholdDocumentManager {
    private let service: any HouseholdDocumentServiceProtocol
    private var observation: ServiceObservation?
    private(set) var documents: [HouseholdDocumentModel] = []

    init(service: any HouseholdDocumentServiceProtocol) {
        self.service = service
    }

    func fetchDocuments(householdID: String) async throws {
        observation?.cancel()
        observation = service.observeDocuments(householdID: householdID, limit: 100) { [weak self] result in
            if case .success(let documents) = result { self?.documents = documents }
        }
        if observation == nil {
            documents = try await service.fetchDocuments(householdID: householdID, limit: 100)
        }
    }

    func createDocument(
        _ document: HouseholdDocumentModel,
        attachment: DocumentAttachmentDraft
    ) async throws {
        let saved = try await service.createDocument(document, attachment: attachment)
        if !documents.contains(where: { $0.id == saved.id }) { documents.insert(saved, at: 0) }
    }

    func updateDocument(_ document: HouseholdDocumentModel) async throws {
        try await service.updateDocument(document)
        if let index = documents.firstIndex(where: { $0.id == document.id }) { documents[index] = document }
    }

    func deleteDocument(_ document: HouseholdDocumentModel) async throws {
        try await service.deleteDocument(document)
        documents.removeAll { $0.id == document.id }
    }

    func clearDocuments() {
        observation?.cancel()
        observation = nil
        documents = []
    }
}
