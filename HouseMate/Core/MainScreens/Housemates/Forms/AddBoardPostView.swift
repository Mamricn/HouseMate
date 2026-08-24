//
//  AddBoardPostView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

struct AddBoardPostView: View {

    @Environment(\.dismiss) private var dismiss

    let onSave: (_ text: String) -> Void

    @State private var text = ""

    private let maximumCharacters = 500

    var body: some View {
        NavigationStack {
            Form {
                Section("Message") {
                    TextField(
                        "What would you like to share?",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(6...12)
                    .textInputAutocapitalization(.sentences)
                    .onChange(of: text) {
                        limitTextLength()
                    }

                    HStack {
                        Spacer()

                        Text(
                            "\(text.count)/\(maximumCharacters)"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            text.count == maximumCharacters
                                ? .orange
                                : .secondary
                        )
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancellationToolbar
                confirmationToolbar
            }
        }
    }

    // MARK: - Toolbar

    private var cancellationToolbar: some ToolbarContent {
        ToolbarItem(
            placement: .cancellationAction
        ) {
            Button("Cancel") {
                dismiss()
            }
        }
    }

    private var confirmationToolbar: some ToolbarContent {
        ToolbarItem(
            placement: .confirmationAction
        ) {
            Button("Post") {
                savePost()
            }
            .disabled(trimmedText.isEmpty)
        }
    }

    // MARK: - Helpers

    private var trimmedText: String {
        text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func limitTextLength() {
        guard text.count > maximumCharacters else {
            return
        }

        text = String(
            text.prefix(maximumCharacters)
        )
    }

    private func savePost() {
        guard !trimmedText.isEmpty else {
            return
        }

        onSave(trimmedText)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddBoardPostView { text in
        print(text)
    }
}
