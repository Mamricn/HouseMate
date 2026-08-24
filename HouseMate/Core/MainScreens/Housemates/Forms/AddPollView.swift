//
//  AddPollView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//



import SwiftUI

struct AddPollView: View {

    @Environment(\.dismiss) private var dismiss

    let onSave: (
        _ question: String,
        _ options: [String],
        _ expiresAt: Date?
    ) -> Void

    @State private var question = ""
    @State private var options = ["", ""]

    @State private var hasExpiryDate = false
    @State private var expiresAt =
        Calendar.autoupdatingCurrent.date(
            byAdding: .day,
            value: 1,
            to: .now
        ) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                questionSection
                optionsSection
                expirySection
            }
            .navigationTitle("New Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancellationToolbar
                confirmationToolbar
            }
        }
    }

    // MARK: - Question

    private var questionSection: some View {
        Section("Question") {
            TextField(
                "What would you like to ask?",
                text: $question,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textInputAutocapitalization(.sentences)
        }
    }

    // MARK: - Options

    private var optionsSection: some View {
        Section {
            ForEach(options.indices, id: \.self) { index in
                HStack {
                    TextField(
                        "Option \(index + 1)",
                        text: $options[index]
                    )
                    .textInputAutocapitalization(.sentences)

                    if options.count > 2 {
                        Button(role: .destructive) {
                            removeOption(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if options.count < 5 {
                Button {
                    options.append("")
                } label: {
                    Label(
                        "Add Option",
                        systemImage: "plus.circle"
                    )
                }
            }
        } header: {
            Text("Options")
        } footer: {
            Text("Add between 2 and 5 unique options.")
        }
    }

    // MARK: - Expiry

    private var expirySection: some View {
        Section("Poll Duration") {
            Toggle(
                "Set End Date",
                isOn: $hasExpiryDate
            )

            if hasExpiryDate {
                DatePicker(
                    "Ends",
                    selection: $expiresAt,
                    in: minimumExpiryDate...,
                    displayedComponents: [
                        .date,
                        .hourAndMinute
                    ]
                )
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
            Button("Create") {
                savePoll()
            }
            .disabled(!canSave)
        }
    }

    // MARK: - Validation

    private var trimmedQuestion: String {
        question.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var trimmedOptions: [String] {
        options
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
    }

    private var hasUniqueOptions: Bool {
        let normalizedOptions = trimmedOptions.map {
            $0.lowercased()
        }

        return Set(normalizedOptions).count
            == normalizedOptions.count
    }

    private var canSave: Bool {
        !trimmedQuestion.isEmpty
            && trimmedOptions.count >= 2
            && hasUniqueOptions
    }

    private var minimumExpiryDate: Date {
        Calendar.autoupdatingCurrent.date(
            byAdding: .minute,
            value: 5,
            to: .now
        ) ?? .now
    }

    // MARK: - Actions

    private func removeOption(at index: Int) {
        guard options.indices.contains(index) else {
            return
        }

        options.remove(at: index)
    }

    private func savePoll() {
        guard canSave else {
            return
        }

        onSave(
            trimmedQuestion,
            trimmedOptions,
            hasExpiryDate ? expiresAt : nil
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddPollView { question, options, expiresAt in
        print(question)
        print(options)
        print(expiresAt as Any)
    }
}
