//
//  QuickActionsView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

struct QuickActionOption: Identifiable {

    let id = UUID()

    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void
}

struct QuickActionsView: View {

    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String
    let options: [QuickActionOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            VStack(spacing: 10) {
                ForEach(options) { option in
                    optionButton(option)
                }
            }

            Spacer(minLength: 0)

            cancelButton
        }
        .padding(20)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Option

    private func optionButton(
        _ option: QuickActionOption
    ) -> some View {
        Button {
            open(option)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.systemImage)
                    .font(
                        .system(
                            size: 19,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(option.color)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                        .fill(option.color.opacity(0.12))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(option.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .frame(height: 66)
            .background {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(Color(.secondarySystemBackground))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cancel

    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background {
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .fill(Color(.secondarySystemBackground))
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action

    private func open(
        _ option: QuickActionOption
    ) {
        dismiss()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.3
        ) {
            option.action()
        }
    }
}

// MARK: - Preview

#Preview {
    QuickActionsView(
        title: "Add to Household",
        subtitle: "Choose what you would like to add.",
        options: [
            QuickActionOption(
                title: "Add Chore",
                subtitle: "Schedule a household task",
                systemImage: "checklist",
                color: .blue,
                action: {}
            ),
            QuickActionOption(
                title: "Shopping Item",
                subtitle: "Add something to the shopping list",
                systemImage: "cart.badge.plus",
                color: .green,
                action: {}
            ),
            QuickActionOption(
                title: "Add Bill",
                subtitle: "Create a new household bill",
                systemImage: "creditcard.fill",
                color: .orange,
                action: {}
            )
        ]
    )
}
