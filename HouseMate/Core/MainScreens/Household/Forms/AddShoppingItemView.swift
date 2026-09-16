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
    @State private var hasAttemptedSubmit = false
    @State private var selectedListID = "groceries"
    var lists: [ShoppingCollection] = []
    var initialListID: String = "groceries"
    var onListSelected: (String) -> Void = { _ in }

    let onSave: (
        _ name: String,
        _ quantity: Int
    ) -> Void

    var body: some View {
        NavigationStack {
            Form {
                if !lists.isEmpty {
                    Section("Shopping List") {
                        Picker("List", selection: $selectedListID) {
                            ForEach(lists) { list in Text(list.name).tag(list.id) }
                        }
                    }
                }
                Section("Item") {
                    TextField(
                        "Item name",
                        text: $itemName
                    )
                    .textInputAutocapitalization(.sentences)

                    if hasAttemptedSubmit && trimmedItemName.isEmpty {
                        FormValidationMessage(message: "Enter an item name.")
                    }
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
            .onAppear { selectedListID = initialListID }
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
        hasAttemptedSubmit = true

        guard !trimmedItemName.isEmpty else {
            HapticFeedback.validationError()
            return
        }

        onListSelected(selectedListID)
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
