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
    var onTogglePurchased: (ShoppingItemModel) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if items.isEmpty {
                Text("Shopping list is empty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                shoppingList
            }
        }
        .padding()
        .background {
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
                .stroke(.white.opacity(0.85), lineWidth: 1)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Shopping List")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showsAddButton {
                Button {

                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var shoppingList: some View {
        List(items) { item in
            ShoppingItemRowView(item: item)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true
                ) {
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
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .frame(height: 140)
    }
}
#Preview("With Items") {
    ShoppingCardView(items: ShoppingItemModel.mockList)
        .padding()
}

#Preview("Empty") {
    ShoppingCardView(items: [])
        .padding()
}
