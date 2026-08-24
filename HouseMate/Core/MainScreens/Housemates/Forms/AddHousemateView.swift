//
//  AddHousemateView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//



import SwiftUI

struct AddHousemateView: View {

    @Environment(\.dismiss) private var dismiss

    let onInvite: (
        _ name: String,
        _ email: String
    ) -> Void

    @State private var name = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "Name",
                        text: $name
                    )
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)

                    TextField(
                        "Email",
                        text: $email
                    )
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                } header: {
                    Text("Housemate")
                } footer: {
                    Text(
                        "The invitation will be connected " +
                        "to Firebase later."
                    )
                }
            }
            .navigationTitle("Invite Housemate")
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
            Button("Invite") {
                inviteHousemate()
            }
            .disabled(!canInvite)
        }
    }

    // MARK: - Validation

    private var trimmedName: String {
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var trimmedEmail: String {
        email
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
    }

    private var canInvite: Bool {
        !trimmedName.isEmpty
            && trimmedEmail.contains("@")
            && trimmedEmail.contains(".")
    }

    // MARK: - Invite

    private func inviteHousemate() {
        guard canInvite else {
            return
        }

        onInvite(
            trimmedName,
            trimmedEmail
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddHousemateView { name, email in
        print(name)
        print(email)
    }
}
