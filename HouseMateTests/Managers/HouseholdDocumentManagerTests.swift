import Foundation
import Testing
@testable import HouseMate

@Suite("HouseholdDocumentManager — document lifecycle")
struct HouseholdDocumentManagerTests {

    @Test("Create, update and delete keep the document list in sync")
    @MainActor
    func managesDocumentLifecycle() async throws {
        let manager = HouseholdDocumentManager(
            service: MockHouseholdDocumentService()
        )
        try await manager.fetchDocuments(householdID: "empty-house")
        #expect(manager.documents.isEmpty)

        var document = makeDocument()
        let attachment = DocumentAttachmentDraft(
            data: Data([1, 2, 3]),
            fileName: "insurance.pdf",
            contentType: "application/pdf"
        )

        try await manager.createDocument(document, attachment: attachment)
        #expect(manager.documents.count == 1)
        #expect(manager.documents.first?.fileName == "insurance.pdf")
        #expect(manager.documents.first?.contentType == "application/pdf")

        document.fileName = "insurance.pdf"
        document.contentType = "application/pdf"
        document.title = "Updated insurance"
        try await manager.updateDocument(document)
        #expect(manager.documents.first?.title == "Updated insurance")

        let updatedDocument = try #require(manager.documents.first)
        try await manager.deleteDocument(updatedDocument)
        #expect(manager.documents.isEmpty)
    }
}

private func makeDocument() -> HouseholdDocumentModel {
    HouseholdDocumentModel(
        documentId: "document",
        householdId: "empty-house",
        createdAt: .now,
        createdByUserId: "user",
        title: "Home insurance",
        category: .insurance,
        fileName: "",
        fileURL: "",
        storagePath: "",
        contentType: ""
    )
}
