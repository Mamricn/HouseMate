//
//  AddShoppingItemView.swift
//  HouseMate
//
//  Created by Marcin Turek on 21/08/2026.
//

import SwiftUI

struct AddShoppingItemView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var itemName = ""
    @State private var quantity = 1

    let onSave: (
        _ name: String,
        _ quantity: Int
    ) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField(
                        "Item name",
                        text: $itemName
                    )
                    .textInputAutocapitalization(.sentences)
                }

                Section("Quantity") {
                    Stepper(
                        value: $quantity,
                        in: 1...99
                    ) {
                        HStack {
                            Text("Quantity")

                            Spacer()

                            Text("\(quantity)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Add") {
                        saveItem()
                    }
                    .disabled(trimmedItemName.isEmpty)
                }
            }
        }
    }

    private var trimmedItemName: String {
        itemName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func saveItem() {
        guard !trimmedItemName.isEmpty else {
            return
        }

        onSave(
            trimmedItemName,
            quantity
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddShoppingItemView { name, quantity in
        print("\(name), quantity: \(quantity)")
    }
}
