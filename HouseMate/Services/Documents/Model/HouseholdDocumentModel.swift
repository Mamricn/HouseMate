import Foundation

struct HouseholdDocumentModel: Identifiable, Codable, Equatable {
    var id: String { documentId }

    let documentId: String
    let householdId: String
    let createdAt: Date?
    let createdByUserId: String

    var title: String
    var category: HouseholdDocumentCategory
    var notes: String?
    var fileName: String
    var fileURL: String
    var storagePath: String
    var contentType: String

    var storeName: String?
    var amount: Double?
    var purchaseDate: Date?
    var warrantyExpiresAt: Date?
    var serialNumber: String?

    enum CodingKeys: String, CodingKey {
        case documentId = "document_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case createdByUserId = "created_by_user_id"
        case title, category, notes
        case fileName = "file_name"
        case fileURL = "file_url"
        case storagePath = "storage_path"
        case contentType = "content_type"
        case storeName = "store_name"
        case amount
        case purchaseDate = "purchase_date"
        case warrantyExpiresAt = "warranty_expires_at"
        case serialNumber = "serial_number"
    }
}

enum HouseholdDocumentCategory: String, Codable, CaseIterable, Identifiable {
    case home
    case groceryReceipt
    case purchaseReceipt
    case insurance
    case warranty
    case bill
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .groceryReceipt: "Grocery Receipt"
        case .purchaseReceipt: "Purchase Receipt"
        case .insurance: "Insurance"
        case .warranty: "Warranty"
        case .bill: "Bill"
        case .other: "Other"
        }
    }

    var filterTitle: String {
        switch self {
        case .groceryReceipt: "Groceries"
        case .purchaseReceipt: "Purchases"
        default: title
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .groceryReceipt: "basket.fill"
        case .purchaseReceipt: "washer.fill"
        case .insurance: "shield.fill"
        case .warranty: "checkmark.seal.fill"
        case .bill: "doc.text.fill"
        case .other: "folder.fill"
        }
    }

    var isReceipt: Bool {
        self == .groceryReceipt || self == .purchaseReceipt
    }
}

struct DocumentAttachmentDraft: Equatable {
    let data: Data
    let fileName: String
    let contentType: String
}

extension HouseholdDocumentModel {
    static let mockList: [HouseholdDocumentModel] = [
        HouseholdDocumentModel(
            documentId: "document_1",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "1",
            title: "Weekly groceries",
            category: .groceryReceipt,
            notes: nil,
            fileName: "receipt.jpg",
            fileURL: "",
            storagePath: "",
            contentType: "image/jpeg",
            storeName: "Tesco",
            amount: 48.72,
            purchaseDate: .now,
            warrantyExpiresAt: nil,
            serialNumber: nil
        ),
        HouseholdDocumentModel(
            documentId: "document_2",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "1",
            title: "Washing machine",
            category: .purchaseReceipt,
            notes: "Keep for warranty",
            fileName: "invoice.pdf",
            fileURL: "",
            storagePath: "",
            contentType: "application/pdf",
            storeName: "Currys",
            amount: 499,
            purchaseDate: .now,
            warrantyExpiresAt: Calendar.current.date(byAdding: .year, value: 2, to: .now),
            serialNumber: "WM-2048"
        )
    ]
}
