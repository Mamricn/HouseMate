//
//  ShoppingListView.swift
//  HouseMate
//

import SwiftUI

struct ShoppingCollectionsView: View {
    let items: [ShoppingItemModel]
    let lists: [ShoppingCollection]
    var initialListID: String = "groceries"
    var onSelect: (String) -> Void
    var onSaveList: (ShoppingCollection) async -> Bool
    var onAdd: () -> Void
    var onQuickAdd: (String, String) -> Void
    var onTogglePurchased: (ShoppingItemModel) -> Void
    var onDelete: (ShoppingItemModel) -> Void
    var onClearPurchased: (String) -> Void
    var onMove: (ShoppingItemModel, String) -> Void

    @State private var selectedID: String?
    @State private var editingList: ShoppingCollection?
    @State private var quickItemName = ""
    @FocusState private var isQuickAddFocused: Bool

    var body: some View {
        ZStack {
            shoppingBackground

            VStack(spacing: 14) {
                listPicker

                if let id = selectedID, lists.contains(where: { $0.id == id }) {
                HStack(spacing: 10) {
                    Image(systemName: selectedList?.symbol ?? "cart.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.mint)

                    TextField(
                        "Add to \(selectedList?.name ?? "list")",
                        text: $quickItemName
                    )
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($isQuickAddFocused)
                    .onSubmit { submitQuickItem(to: id) }

                    Button {
                        submitQuickItem(to: id)
                    } label: {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.mint, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(trimmedQuickItemName.isEmpty)
                    .opacity(trimmedQuickItemName.isEmpty ? 0.45 : 1)
                    .accessibilityLabel("Add item to \(selectedList?.name ?? "shopping list")")
                }
                .padding(.leading, 14)
                .padding(.trailing, 5)
                .frame(height: 46)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().stroke(.white.opacity(0.55), lineWidth: 1) }
                .padding(.horizontal, 18)

                ShoppingListView(
                    items: items.filter { $0.shoppingListID == id },
                    onAdd: { onSelect(id); onAdd() },
                    onTogglePurchased: onTogglePurchased,
                    onDelete: onDelete,
                    onClearPurchased: { onClearPurchased(id) },
                    lists: lists,
                    onMove: onMove,
                    showsSummary: false,
                    showsAddButton: false,
                    showsBackground: false
                )
                } else {
                    ContentUnavailableView("No shopping lists", systemImage: "cart", description: Text("Create your first shared shopping list."))
                    Spacer()
                }
            }
            .padding(.top, 12)
        }
        .onAppear { selectInitialListIfNeeded() }
        .onChange(of: lists) { _, _ in selectInitialListIfNeeded() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add Item", systemImage: "cart.badge.plus") {
                        guard let selectedID else { return }
                        onSelect(selectedID)
                        onAdd()
                    }
                    .disabled(selectedID == nil)

                    Button("Create List", systemImage: "folder.badge.plus") {
                        editingList = ShoppingCollection(id: UUID().uuidString, name: "", symbol: "cart.fill")
                    }

                    if let selectedList {
                        Button("Edit \(selectedList.name)", systemImage: "pencil") {
                            editingList = selectedList
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Shopping actions")
            }
        }
        .sheet(item: $editingList) { list in
            ShoppingCollectionEditor(list: list, onSave: onSaveList)
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
    }

    private var selectedList: ShoppingCollection? {
        lists.first { $0.id == selectedID }
    }

    private var listPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(lists) { list in
                    let listItems = items.filter { $0.shoppingListID == list.id }
                    let remainingCount = listItems.filter { !$0.isPurchased }.count
                    let completion = listItems.isEmpty
                        ? 0
                        : Double(listItems.count - remainingCount) / Double(listItems.count)

                    Button {
                        withAnimation(.snappy) {
                            selectedID = list.id
                            onSelect(list.id)
                        }
                    } label: {
                        HStack(spacing: 9) {
                            ZStack {
                                Circle()
                                    .stroke(
                                        selectedID == list.id
                                            ? Color.white.opacity(0.28)
                                            : Color.mint.opacity(0.18),
                                        lineWidth: 3
                                    )

                                Circle()
                                    .trim(from: 0, to: completion)
                                    .stroke(
                                        selectedID == list.id ? Color.white : Color.mint,
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))

                                Text("\(remainingCount)")
                                    .font(.caption2.weight(.bold))
                                    .monospacedDigit()
                            }
                            .frame(width: 27, height: 27)

                            Image(systemName: list.symbol)
                                .font(.caption.weight(.semibold))

                            Text(list.name)
                                .lineLimit(1)
                        }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedID == list.id ? Color.white : Color.primary)
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(selectedID == list.id ? Color.mint : Color.primary.opacity(0.06), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .contextMenu { Button("Edit list", systemImage: "pencil") { editingList = list } }
                }
            }
            .padding(.horizontal, 18)
        }
        .scrollIndicators(.hidden)
    }

    private var shoppingBackground: some View {
        LinearGradient(colors: [.mint.opacity(0.12), .blue.opacity(0.08), .purple.opacity(0.06), Color(.secondarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    private func selectInitialListIfNeeded() {
        guard !lists.isEmpty else { selectedID = nil; return }
        if selectedID == nil || !lists.contains(where: { $0.id == selectedID }) {
            let initial = lists.first(where: { $0.id == initialListID })
                ?? lists.first(where: { $0.id == "groceries" })
                ?? lists[0]
            selectedID = initial.id
            onSelect(initial.id)
        }
    }

    private var trimmedQuickItemName: String {
        quickItemName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submitQuickItem(to listID: String) {
        guard !trimmedQuickItemName.isEmpty else {
            HapticFeedback.validationError()
            return
        }

        let name = trimmedQuickItemName
        quickItemName = ""
        HapticFeedback.selection()
        onSelect(listID)
        onQuickAdd(name, listID)
        isQuickAddFocused = true
    }
}

private struct ShoppingCollectionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var list: ShoppingCollection
    var onSave: (ShoppingCollection) async -> Bool
    @State private var isSaving = false
    @State private var error = false
    private let symbols = ["cart.fill", "basket.fill", "house.fill", "bed.double.fill", "cable.connector", "bag.fill"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("List name, e.g. Tesco or Home", text: $list.name)
                HStack {
                    ForEach(symbols, id: \.self) { symbol in
                        Button { list.symbol = symbol } label: {
                            Image(systemName: symbol).frame(maxWidth: .infinity).frame(height: 36)
                                .foregroundStyle(list.symbol == symbol ? Color.white : Color.mint)
                                .background(list.symbol == symbol ? Color.mint : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain)
                    }
                }
                if error { Text("Could not save. Please try again.").foregroundStyle(.red).font(.caption) }
            }
            .navigationTitle(list.name.isEmpty ? "New Shopping List" : "Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        list.name = list.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        isSaving = true
                        Task {
                            if await onSave(list) { dismiss() } else { error = true }
                            isSaving = false
                        }
                    }
                    .disabled(isSaving || list.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || list.name.count > 60)
                }
            }
        }
    }
}

struct ShoppingListView: View {

    let items: [ShoppingItemModel]
    var onAdd: () -> Void = {}
    var onTogglePurchased: (ShoppingItemModel) -> Void = { _ in }
    var onDelete: (ShoppingItemModel) -> Void = { _ in }
    var onClearPurchased: () -> Void = {}
    var lists: [ShoppingCollection] = []
    var onMove: (ShoppingItemModel, String) -> Void = { _, _ in }
    var showsSummary = true
    var showsAddButton = true
    var showsBackground = true

    @State private var showsClearConfirmation = false

    var body: some View {
        ZStack {
            if showsBackground { backgroundGradient }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if showsSummary { summaryCard }

                    if items.isEmpty {
                        emptyState
                    } else {
                        if !itemsToBuy.isEmpty {
                            itemSection(title: "TO BUY", items: itemsToBuy)
                        }

                        if !purchasedItems.isEmpty {
                            purchasedHeader
                            itemSection(title: nil, items: purchasedItems)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar {
            if showsAddButton {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add shopping item")
            }
            }
        }
        .confirmationDialog(
            "Clear purchased items?",
            isPresented: $showsClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Purchased", role: .destructive, action: onClearPurchased)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all purchased items from the shopping list.")
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.mint.opacity(0.16), lineWidth: 7)

                Circle()
                    .trim(from: 0, to: completionProgress)
                    .stroke(
                        Color.mint,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Image(systemName: completionProgress == 1 ? "checkmark" : "cart.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.mint)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(summaryTitle)
                    .font(.headline)

                Text(summarySubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.55))
            }

            Spacer()

            if !items.isEmpty {
                Text("\(purchasedItems.count)/\(items.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
        }
        .padding(18)
        .shoppingSurface()
        .animation(.snappy(duration: 0.25), value: purchasedItems.count)
    }

    private var purchasedHeader: some View {
        HStack {
            Text("PURCHASED")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary.opacity(0.52))

            Spacer()

            Button("Clear") {
                showsClearConfirmation = true
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.red)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, -8)
    }

    private func itemSection(
        title: String?,
        items: [ShoppingItemModel]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary.opacity(0.52))
                    .padding(.horizontal, 4)
            }

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HouseMateSwipeRow(
                        leadingAction: HouseMateSwipeAction(
                            accessibilityLabel: "Delete \(item.name)",
                            systemImage: "trash.fill",
                            color: .red,
                            action: { onDelete(item) }
                        ),
                        trailingAction: nil
                    ) {
                        shoppingRow(item)
                            .contextMenu {
                                Menu("Move to list") {
                                    ForEach(lists.filter { $0.id != item.shoppingListID }) { list in
                                        Button(list.name, systemImage: list.symbol) { onMove(item, list.id) }
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticFeedback.selection()
                                onTogglePurchased(item)
                            }
                            .padding(.vertical, 10)
                    }

                    if index < items.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .padding(.horizontal, 14)
            .shoppingSurface()
        }
    }

    private func shoppingRow(_ item: ShoppingItemModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(
                    item.isPurchased
                        ? Color.green
                        : Color.primary.opacity(0.48)
                )
                .contentTransition(.symbolEffect(.replace))

            Text(item.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(
                    item.isPurchased
                        ? Color.primary.opacity(0.52)
                        : Color.primary
                )
                .strikethrough(
                    item.isPurchased,
                    color: Color.primary.opacity(0.52)
                )
                .lineLimit(2)

            Spacer(minLength: 8)

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary.opacity(0.55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.06), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.22), value: item.isPurchased)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Shopping list is empty",
            systemImage: "cart",
            description: Text("Add the first item you need from the shop.")
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 54)
    }

    private var itemsToBuy: [ShoppingItemModel] {
        items
            .filter { !$0.isPurchased }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    private var purchasedItems: [ShoppingItemModel] {
        items
            .filter(\.isPurchased)
            .sorted {
                ($0.purchasedAt ?? $0.createdAt ?? .distantPast)
                    > ($1.purchasedAt ?? $1.createdAt ?? .distantPast)
            }
    }

    private var completionProgress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(purchasedItems.count) / Double(items.count)
    }

    private var summaryTitle: String {
        if items.isEmpty { return "Ready for your next shop" }
        if itemsToBuy.isEmpty { return "Everything purchased" }
        return "Shopping progress"
    }

    private var summarySubtitle: String {
        switch itemsToBuy.count {
        case 0:
            return items.isEmpty ? "Your household list starts here" : "Your list is complete"
        case 1:
            return "1 item remaining"
        default:
            return "\(itemsToBuy.count) items remaining"
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color(.secondarySystemBackground)
            LinearGradient(
                colors: [
                    Color.mint.opacity(0.17),
                    Color.cyan.opacity(0.11),
                    Color.blue.opacity(0.07),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func shoppingSurface() -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

#Preview {
    NavigationStack {
        ShoppingListView(items: ShoppingItemModel.mockList)
            .navigationTitle("Shopping List")
    }
}
