import SwiftUI

struct EditDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    let document: HouseholdDocumentModel
    let onSave: (HouseholdDocumentModel) -> Void

    @State private var title: String
    @State private var category: HouseholdDocumentCategory
    @State private var notes: String
    @State private var storeName: String
    @State private var amount: String
    @State private var purchaseDate: Date
    @State private var warrantyExpiresAt: Date
    @State private var hasWarranty: Bool
    @State private var serialNumber: String

    init(document: HouseholdDocumentModel, onSave: @escaping (HouseholdDocumentModel) -> Void) {
        self.document = document
        self.onSave = onSave
        _title = State(initialValue: document.title)
        _category = State(initialValue: document.category)
        _notes = State(initialValue: document.notes ?? "")
        _storeName = State(initialValue: document.storeName ?? "")
        _amount = State(initialValue: document.amount.map { String($0) } ?? "")
        _purchaseDate = State(initialValue: document.purchaseDate ?? .now)
        _warrantyExpiresAt = State(initialValue: document.warrantyExpiresAt ?? Calendar.current.date(byAdding: .year, value: 2, to: .now) ?? .now)
        _hasWarranty = State(initialValue: document.warrantyExpiresAt != nil)
        _serialNumber = State(initialValue: document.serialNumber ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    TextField("Name", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(HouseholdDocumentCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                }

                if category.isReceipt {
                    Section(category == .groceryReceipt ? "Receipt" : "Purchase") {
                        TextField("Store", text: $storeName)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        if category == .purchaseReceipt {
                            TextField("Serial Number (optional)", text: $serialNumber)
                            Toggle("Has Warranty", isOn: $hasWarranty)
                            if hasWarranty {
                                DatePicker("Warranty Ends", selection: $warrantyExpiresAt, displayedComponents: .date)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical).lineLimit(3...6)
                }

                Section("Attachment") {
                    Label(document.fileName, systemImage: document.contentType == "application/pdf" ? "doc.richtext" : "photo.fill")
                    Text("The existing attachment will be kept.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) }
            }
        }
    }

    private func save() {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else { return }

        var updated = document
        updated.title = cleanedTitle
        updated.category = category
        updated.notes = cleaned(notes)
        updated.storeName = category.isReceipt ? cleaned(storeName) : nil
        updated.amount = category.isReceipt ? Double(amount.replacingOccurrences(of: ",", with: ".")) : nil
        updated.purchaseDate = category.isReceipt ? purchaseDate : nil
        updated.serialNumber = category == .purchaseReceipt ? cleaned(serialNumber) : nil
        updated.warrantyExpiresAt = category == .purchaseReceipt && hasWarranty ? warrantyExpiresAt : nil
        onSave(updated)
        dismiss()
    }

    private func cleaned(_ value: String) -> String? {
        let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
}
