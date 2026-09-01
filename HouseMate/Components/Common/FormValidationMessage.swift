//
//  FormValidationMessage.swift
//  HouseMate
//

import SwiftUI

struct FormValidationMessage: View {

    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.caption)
            .foregroundStyle(.red)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .accessibilityLabel("Error: \(message)")
    }
}
