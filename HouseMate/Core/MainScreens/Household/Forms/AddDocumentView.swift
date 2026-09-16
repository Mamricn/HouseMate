import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AddDocumentView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (
        String,
        HouseholdDocumentCategory,
        String?,
        String?,
        Double?,
        Date?,
        Date?,
        String?,
        DocumentAttachmentDraft
    ) -> Void

    @State private var title = ""
    @State private var category: HouseholdDocumentCategory = .home
    @State private var notes = ""
    @State private var storeName = ""
    @State private var amount = ""
    @State private var purchaseDate = Date.now
    @State private var warrantyExpiresAt = Calendar.current.date(byAdding: .year, value: 2, to: .now) ?? .now
    @State private var hasWarranty = false
    @State private var serialNumber = ""
    @State private var attachment: DocumentAttachmentDraft?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showsFileImporter = false
    @State private var hasAttemptedSubmit = false
    @State private var attachmentError: String?

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

                    if hasAttemptedSubmit && trimmedTitle.isEmpty {
                        FormValidationMessage(message: "Enter a document name.")
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
                                DatePicker(
                                    "Warranty Ends",
                                    selection: $warrantyExpiresAt,
                                    displayedComponents: .date
                                )
                            }
                        }
                    }
                }

                Section("Attachment") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose Photo", systemImage: "photo")
                    }

                    Button {
                        showsFileImporter = true
                    } label: {
                        Label("Choose PDF or File", systemImage: "doc")
                    }

                    if let attachment {
                        Label(attachment.fileName, systemImage: attachment.contentType == "application/pdf" ? "doc.richtext" : "photo.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let attachmentError {
                        FormValidationMessage(message: attachmentError)
                    } else if hasAttemptedSubmit && attachment == nil {
                        FormValidationMessage(message: "Choose a photo or PDF.")
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: save)
                }
            }
            .onChange(of: selectedPhoto) {
                guard let selectedPhoto else { return }
                Task {
                    do {
                        guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
                            throw CocoaError(.fileReadCorruptFile)
                        }
                        attachment = DocumentAttachmentDraft(
                            data: data,
                            fileName: "document-\(UUID().uuidString).jpg",
                            contentType: "image/jpeg"
                        )
                        attachmentError = nil
                    } catch {
                        attachmentError = "The selected photo could not be loaded."
                    }
                }
            }
            .fileImporter(
                isPresented: $showsFileImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                importFile(result)
            }
        }
    }

    private func save() {
        hasAttemptedSubmit = true
        guard !trimmedTitle.isEmpty, let attachment else {
            HapticFeedback.validationError()
            return
        }

        onSave(
            trimmedTitle,
            category,
            cleaned(notes),
            category.isReceipt ? cleaned(storeName) : nil,
            category.isReceipt ? parsedAmount : nil,
            category.isReceipt ? purchaseDate : nil,
            category == .purchaseReceipt && hasWarranty ? warrantyExpiresAt : nil,
            category == .purchaseReceipt ? cleaned(serialNumber) : nil,
            attachment
        )
        dismiss()
    }

    private func importFile(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            guard data.count <= 15 * 1024 * 1024 else {
                attachmentError = "The attachment must be smaller than 15 MB."
                return
            }
            let contentType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
                ?? "application/octet-stream"
            attachment = DocumentAttachmentDraft(data: data, fileName: url.lastPathComponent, contentType: contentType)
            attachmentError = nil
        } catch {
            attachmentError = "The selected file could not be loaded."
        }
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var parsedAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: "."))
    }
    private func cleaned(_ value: String) -> String? {
        let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
}

#Preview {
    AddDocumentView { _, _, _, _, _, _, _, _, _ in }
}
