import SwiftUI

struct DocumentsView: View {
    let documents: [HouseholdDocumentModel]
    let currentUserId: String
    let householdOwnerUserId: String
    var onAdd: () -> Void = {}
    var onDelete: (HouseholdDocumentModel) -> Void = { _ in }
    var onUpdate: (HouseholdDocumentModel) -> Void = { _ in }

    @State private var selectedCategory: HouseholdDocumentCategory?
    @State private var selectedDocument: HouseholdDocumentModel?
    @State private var editingDocument: HouseholdDocumentModel?
    @State private var previewImage: DocumentImagePreview?

    var body: some View {
        ZStack {
            backgroundGradient
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    categoryPicker

                    if filteredDocuments.isEmpty {
                        emptyState
                    } else {
                        documentList
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onAdd()
                } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add document")
            }
        }
        .sheet(item: $selectedDocument) { document in
            documentDetails(document)
                .presentationDetents([.height(600), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterButton("All", category: nil)
                ForEach(HouseholdDocumentCategory.allCases) { category in
                    filterButton(category.filterTitle, category: category)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func filterButton(_ title: String, category: HouseholdDocumentCategory?) -> some View {
        Button {
            withAnimation(.snappy) { selectedCategory = category }
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(selectedCategory == category ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(selectedCategory == category ? Color.blue : Color.primary.opacity(0.06), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var documentList: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredDocuments.enumerated()), id: \.element.id) { index, document in
                HouseMateSwipeRow(leadingAction: deleteAction(document), trailingAction: nil) {
                    documentRow(document)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDocument = document
                        }
                        .padding(.vertical, 10)
                }
                if index < filteredDocuments.count - 1 { Divider().padding(.leading, 58) }
            }
        }
        .padding(.horizontal, 14)
        .documentSurface()
    }

    private func documentRow(_ document: HouseholdDocumentModel) -> some View {
        HStack(spacing: 12) {
            HouseMateSymbolView(
                systemName: document.category.systemImage,
                color: categoryColor(document.category),
                size: 42,
                symbolSize: 17
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title).font(.subheadline).fontWeight(.semibold).lineLimit(1)
                HStack(spacing: 5) {
                    Text(document.category.title)
                    if let amount = document.amount {
                        Text("•")
                        Text(amount, format: .currency(code: "GBP"))
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.55))
            }
            Spacer()
            if let expiry = document.warrantyExpiresAt {
                Text(expiry > .now ? "Warranty" : "Expired")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(expiry > .now ? .green : .red)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background((expiry > .now ? Color.green : Color.red).opacity(0.1), in: Capsule())
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.primary.opacity(0.28))
        }
    }

    private func documentDetails(_ document: HouseholdDocumentModel) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    attachmentPreview(document)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.title).font(.title2).fontWeight(.bold)
                        Text(document.category.title).foregroundStyle(.secondary)
                    }
                    detailFields(document)
                    if let notes = document.notes, !notes.isEmpty {
                        Text(notes).font(.subheadline).padding(16).frame(maxWidth: .infinity, alignment: .leading).documentSurface()
                    }
                    if canDelete(document) {
                        Button(role: .destructive) {
                            selectedDocument = nil
                            onDelete(document)
                        } label: {
                            Label("Delete Document", systemImage: "trash").frame(maxWidth: .infinity).frame(height: 52)
                        }
                        .buttonStyle(.plain)
                        .background(Color.red.opacity(0.09), in: Capsule())
                    }
                }
                .padding(18)
            }
            .background(backgroundGradient)
            .navigationTitle("Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if canDelete(document) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Edit") {
                            editingDocument = document
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { selectedDocument = nil } }
            }
            .sheet(item: $editingDocument) { document in
                EditDocumentView(document: document) { updatedDocument in
                    onUpdate(updatedDocument)
                    selectedDocument = nil
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .fullScreenCover(item: $previewImage) { preview in
                fullScreenImagePreview(preview)
            }
        }
    }

    @ViewBuilder
    private func attachmentPreview(_ document: HouseholdDocumentModel) -> some View {
        if document.contentType.hasPrefix("image/"), let url = URL(string: document.fileURL), !document.fileURL.isEmpty {
            Button {
                previewImage = DocumentImagePreview(url: url, title: document.title)
            } label: {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ContentUnavailableView("Image unavailable", systemImage: "photo.badge.exclamationmark")
                    default:
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.42), in: Circle())
                        .padding(12)
                }
            }
            .buttonStyle(.plain)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityLabel("Open \(document.title) image full screen")
        } else {
            VStack(spacing: 12) {
                Image(systemName: "doc.richtext.fill").font(.system(size: 44)).foregroundStyle(.blue)
                Text(document.fileName).font(.subheadline).lineLimit(2)
                if let url = URL(string: document.fileURL), !document.fileURL.isEmpty {
                    Link("Open File", destination: url).buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 180).documentSurface()
        }
    }

    private func fullScreenImagePreview(_ preview: DocumentImagePreview) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: preview.url) { phase in
                switch phase {
                case .success(let image):
                    ZoomableDocumentImage(image: image)
                        .padding(.horizontal, 8)
                case .failure:
                    ContentUnavailableView(
                        "Image unavailable",
                        systemImage: "photo.badge.exclamationmark"
                    )
                    .foregroundStyle(.white)
                default:
                    ProgressView().tint(.white)
                }
            }

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.58),
                        Color.black.opacity(0.20),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 130)

                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack {
                HStack {
                    Text(preview.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(.black.opacity(0.42), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.24), lineWidth: 0.8)
                        }
                        .shadow(color: .black.opacity(0.20), radius: 6, y: 2)

                    Spacer()

                    Button {
                        previewImage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.black.opacity(0.48), in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(.white.opacity(0.35), lineWidth: 0.8)
                            }
                            .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                Spacer()
            }
        }
    }

    private func detailFields(_ document: HouseholdDocumentModel) -> some View {
        VStack(spacing: 12) {
            if let store = document.storeName { detailLine("Store", value: store) }
            if let amount = document.amount { detailLine("Amount", value: amount.formatted(.currency(code: "GBP"))) }
            if let date = document.purchaseDate { detailLine("Purchased", value: date.formatted(date: .long, time: .omitted)) }
            if let serial = document.serialNumber { detailLine("Serial number", value: serial) }
            if let expiry = document.warrantyExpiresAt { detailLine("Warranty ends", value: expiry.formatted(date: .long, time: .omitted)) }
            detailLine("File", value: document.fileName)
        }
        .padding(16)
        .documentSurface()
    }

    private func detailLine(_ title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium).multilineTextAlignment(.trailing)
        }.font(.subheadline)
    }

    private func deleteAction(_ document: HouseholdDocumentModel) -> HouseMateSwipeAction? {
        guard canDelete(document) else { return nil }
        return HouseMateSwipeAction(accessibilityLabel: "Delete \(document.title)", systemImage: "trash.fill", color: .red) {
            onDelete(document)
        }
    }

    private func canDelete(_ document: HouseholdDocumentModel) -> Bool {
        document.createdByUserId == currentUserId || currentUserId == householdOwnerUserId
    }

    private var filteredDocuments: [HouseholdDocumentModel] {
        documents.filter { selectedCategory == nil || $0.category == selectedCategory }
    }

    private var emptyState: some View {
        ContentUnavailableView("No documents", systemImage: "folder", description: Text("Add a receipt, warranty, insurance document or PDF."))
            .frame(maxWidth: .infinity).padding(.top, 54)
    }

    private func categoryColor(_ category: HouseholdDocumentCategory) -> Color {
        switch category {
        case .home: .blue
        case .groceryReceipt: .green
        case .purchaseReceipt: .indigo
        case .insurance: .cyan
        case .warranty: .orange
        case .bill: .purple
        case .other: .gray
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color(.secondarySystemBackground)
            LinearGradient(colors: [.blue.opacity(0.15), .cyan.opacity(0.09), .indigo.opacity(0.06), Color(.secondarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }.ignoresSafeArea()
    }
}

private struct DocumentImagePreview: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
}

private struct ZoomableDocumentImage: View {
    let image: Image

    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var settledOffset: CGSize = .zero

    private let minimumScale: CGFloat = 1
    private let maximumScale: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            image
                .resizable()
                .scaledToFit()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .contentShape(Rectangle())
                .simultaneousGesture(magnificationGesture(in: proxy.size))
                .simultaneousGesture(dragGesture)
                .onTapGesture(count: 2, perform: toggleZoom)
                .animation(.smooth(duration: 0.25), value: scale)
                .animation(.smooth(duration: 0.25), value: offset)
        }
    }

    private func magnificationGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposedScale = settledScale * value.magnification
                let newScale = min(max(proposedScale, minimumScale), maximumScale)
                let scaleRatio = newScale / settledScale
                let anchor = CGPoint(
                    x: (value.startAnchor.x - 0.5) * size.width,
                    y: (value.startAnchor.y - 0.5) * size.height
                )

                scale = newScale
                offset = CGSize(
                    width: settledOffset.width + (1 - scaleRatio) * (anchor.x - settledOffset.width),
                    height: settledOffset.height + (1 - scaleRatio) * (anchor.y - settledOffset.height)
                )
            }
            .onEnded { _ in
                settledScale = scale
                settledOffset = offset
                if scale <= minimumScale {
                    resetZoom()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > minimumScale else { return }
                offset = CGSize(
                    width: settledOffset.width + value.translation.width,
                    height: settledOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard scale > minimumScale else {
                    resetZoom()
                    return
                }
                settledOffset = offset
            }
    }

    private func toggleZoom() {
        if scale > minimumScale {
            resetZoom()
        } else {
            scale = 2.5
            settledScale = 2.5
        }
    }

    private func resetZoom() {
        scale = minimumScale
        settledScale = minimumScale
        offset = .zero
        settledOffset = .zero
    }
}

private extension View {
    func documentSurface() -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.5), lineWidth: 1) }
            .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

#Preview {
    NavigationStack {
        DocumentsView(documents: HouseholdDocumentModel.mockList, currentUserId: "1", householdOwnerUserId: "1")
            .navigationTitle("Documents")
    }
}
