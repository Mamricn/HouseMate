//
//  ShoppingCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


import SwiftUI

struct ShoppingCardView: View {

    let items: [ShoppingItemModel]

    var showsAddButton: Bool = true

    var onAdd: () -> Void = {}
    var onTogglePurchased: (ShoppingItemModel) -> Void = { _ in }

    var onDelete: ((ShoppingItemModel) -> Void)? = nil
    var onClearPurchased: (() -> Void)? = nil

    @State private var showsClearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if items.isEmpty {
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
        }
    }

    // MARK: - List

    private var shoppingList: some View {
        List {
            ForEach(sortedItems) { item in
                ShoppingItemRowView(item: item)
                    .listRowInsets(
                        EdgeInsets(
                            top: 2,
                            leading: 0,
                            bottom: 2,
                            trailing: 0
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // Delete po lewej
                    .swipeActions(
                        edge: .leading,
                        allowsFullSwipe: false
                    ) {
                        if onDelete != nil {
                            deleteButton(for: item)
                        }
                    }

                    // Purchased po prawej
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: true
                    ) {
                        togglePurchasedButton(for: item)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 180)
    }

    // MARK: - Actions

    private func togglePurchasedButton(
        for item: ShoppingItemModel
    ) -> some View {
        Button {
            onTogglePurchased(item)
        } label: {
            Label(
                item.isPurchased
                    ? "Add Back"
                    : "Purchased",
                systemImage: item.isPurchased
                    ? "arrow.uturn.backward.circle"
                    : "cart.badge.checkmark"
            )
        }
        .tint(
            item.isPurchased
                ? .orange
                : .green
        )
    }

    private func deleteButton(
        for item: ShoppingItemModel
    ) -> some View {
        Button(role: .destructive) {
            onDelete?(item)
        } label: {
            Label(
                "Delete",
                systemImage: "trash.fill"
            )
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
        items.sorted { firstItem, secondItem in
            if firstItem.isPurchased != secondItem.isPurchased {
                return !firstItem.isPurchased
            }

            return (firstItem.createdAt ?? .distantPast)
                > (secondItem.createdAt ?? .distantPast)
        }
    }

    private var remainingItemsCount: Int {
        items.filter {
            !$0.isPurchased
        }.count
    }

    private var purchasedItemsCount: Int {
        items.filter {
            $0.isPurchased
        }.count
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
        .fill(.ultraThickMaterial)
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
