//
//  ShoppingCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


import SwiftUI

struct ShoppingCardView: View {

    let items: [ShoppingItemModel]
    var lists: [ShoppingCollection] = [.groceries]

    var showsAddButton: Bool = true
    var usesThinMaterial: Bool = true

    var onAdd: () -> Void = {}
    var onOpenAll: (String) -> Void = { _ in }
    var onTogglePurchased: (ShoppingItemModel) -> Void = { _ in }

    var onDelete: ((ShoppingItemModel) -> Void)? = nil
    var onClearPurchased: (() -> Void)? = nil

    @State private var showsClearConfirmation = false
    @State private var selectedListID = "groceries"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            listPicker

            if selectedItems.isEmpty {
                emptyState
            } else {
                shoppingList
                clearPurchasedButton
            }
        }
        .padding()
        .background {
            cardBackground
        }
        .onAppear { validateSelection() }
        .onChange(of: lists) { _, _ in validateSelection() }
        .confirmationDialog(
            "Clear purchased items?",
            isPresented: $showsClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Clear Purchased",
                role: .destructive
            ) {
                onClearPurchased?()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will remove all purchased items from the shopping list."
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Shopping List")
                    .font(.title3)
                    .fontWeight(.semibold)

                if !items.isEmpty {
                    Text(remainingItemsText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if showsAddButton {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }

            Button {
                onOpenAll(selectedListID)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open shopping list")
        }
    }

    private var listPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(lists) { list in
                    let listItems = items.filter { $0.shoppingListID == list.id }
                    let remaining = listItems.filter { !$0.isPurchased }.count
                    let completion = listItems.isEmpty
                        ? 0
                        : Double(listItems.count - remaining) / Double(listItems.count)

                    Button {
                        withAnimation(.snappy) { selectedListID = list.id }
                    } label: {
                        HStack(spacing: 7) {
                            ZStack {
                                Circle()
                                    .stroke(
                                        selectedListID == list.id
                                            ? Color.white.opacity(0.3)
                                            : Color.mint.opacity(0.2),
                                        lineWidth: 3
                                    )
                                Circle()
                                    .trim(from: 0, to: completion)
                                    .stroke(
                                        selectedListID == list.id ? Color.white : Color.mint,
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                Text("\(remaining)")
                                    .font(.caption2.bold())
                                    .monospacedDigit()
                            }
                            .frame(width: 25, height: 25)

                            Text(list.name).lineLimit(1)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedListID == list.id ? Color.white : Color.primary)
                        .padding(.horizontal, 11)
                        .frame(height: 39)
                        .background(
                            selectedListID == list.id ? Color.mint : Color.primary.opacity(0.06),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - List

    private var shoppingList: some View {
        VStack(spacing: 8) {
                ForEach(Array(sortedItems.prefix(3))) { item in
                    HouseMateSwipeRow(
                        leadingAction: deleteAction(for: item),
                        trailingAction: nil
                    ) {
                        ShoppingItemRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticFeedback.selection()
                                onTogglePurchased(item)
                            }
                            .padding(.vertical, 4)
                    }
                }

                if hiddenItemsCount > 0 {
                    Button("+\(hiddenItemsCount) more") { onOpenAll(selectedListID) }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
    }

    // MARK: - Actions

    private func deleteAction(for item: ShoppingItemModel) -> HouseMateSwipeAction? {
        guard onDelete != nil else { return nil }

        return HouseMateSwipeAction(
            accessibilityLabel: "Delete \(item.name)",
            systemImage: "trash.fill",
            color: .red
        ) {
            onDelete?(item)
        }
    }

    @ViewBuilder
    private var clearPurchasedButton: some View {
        if purchasedItemsCount > 0,
           onClearPurchased != nil {
            Button(role: .destructive) {
                showsClearConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")

                    Text("Clear Purchased")

                    Spacer()

                    Text("\(purchasedItemsCount)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "cart")
                .foregroundStyle(.secondary)

            Text("Shopping list is empty")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    // MARK: - Calculated Values

    private var sortedItems: [ShoppingItemModel] {
        selectedItems.sorted { firstItem, secondItem in
            if firstItem.isPurchased != secondItem.isPurchased {
                return !firstItem.isPurchased
            }

            return (firstItem.createdAt ?? .distantPast)
                > (secondItem.createdAt ?? .distantPast)
        }
    }

    private var selectedItems: [ShoppingItemModel] {
        items.filter { $0.shoppingListID == selectedListID }
    }

    private var hiddenItemsCount: Int {
        max(0, sortedItems.count - 3)
    }

    private var remainingItemsCount: Int {
        selectedItems.filter {
            !$0.isPurchased
        }.count
    }

    private var purchasedItemsCount: Int {
        selectedItems.filter {
            $0.isPurchased
        }.count
    }

    private func validateSelection() {
        guard !lists.isEmpty else { return }
        if !lists.contains(where: { $0.id == selectedListID }) {
            selectedListID = lists.first(where: { $0.id == "groceries" })?.id
                ?? lists[0].id
        }
    }

    private var remainingItemsText: String {
        switch remainingItemsCount {
        case 0:
            return "Everything purchased"

        case 1:
            return "1 item remaining"

        default:
            return "\(remainingItemsCount) items remaining"
        }
    }

    // MARK: - Background

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 24,
            style: .continuous
        )
        .fill(usesThinMaterial ? Material.ultraThin : Material.ultraThick)
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                .white.opacity(0.35),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Previews

#Preview("Shopping List") {
    ShoppingCardView(
        items: ShoppingItemModel.mockList,
        onAdd: {
            print("Add")
        },
        onTogglePurchased: { item in
            print("Toggle \(item.name)")
        },
        onDelete: { item in
            print("Delete \(item.name)")
        },
        onClearPurchased: {
            print("Clear purchased")
        }
    )
    .padding()
}

#Preview("Empty") {
    ShoppingCardView(items: [])
        .padding()
}
