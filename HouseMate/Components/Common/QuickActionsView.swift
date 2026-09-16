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

    enum Layout {
        case list
        case grid
        case themedList
    }

    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String
    let options: [QuickActionOption]
    var layout: Layout = .list

    var body: some View {
        ZStack {
            if layout != .list {
                gridBackground
                    .ignoresSafeArea()
            }

            VStack(alignment: .leading, spacing: 18) {
                header

                if layout == .grid {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(options) { option in
                            gridOptionButton(option)
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(options) { option in
                            optionButton(option, themed: layout == .themedList)
                        }
                    }
                }

                Spacer(minLength: 0)

                cancelButton
            }
            .padding(20)
            .padding(.top, layout == .list ? 0 : 12)
        }
    }

    private var gridBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.95, blue: 1.00),
                    Color(red: 0.95, green: 0.89, blue: 0.98),
                    Color(red: 0.91, green: 0.96, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.13))
                .frame(width: 190, height: 190)
                .blur(radius: 35)
                .offset(x: 145, y: -180)

            Circle()
                .fill(Color.purple.opacity(0.11))
                .frame(width: 210, height: 210)
                .blur(radius: 40)
                .offset(x: -150, y: 190)
        }
    }

    private func gridOptionButton(
        _ option: QuickActionOption
    ) -> some View {
        Button {
            open(option)
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    customGridIcon(option)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary.opacity(0.22))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(option.subtitle)
                        .font(.caption2)
                        .foregroundStyle(Color.primary.opacity(0.48))
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.62), lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private func customGridIcon(_ option: QuickActionOption) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            option.color.opacity(0.92),
                            option.color.opacity(0.62)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 25, height: 25)
                .offset(x: 13, y: -13)
                .blur(radius: 1)

            Image(systemName: option.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
        }
        .frame(width: 40, height: 40)
        .shadow(color: option.color.opacity(0.22), radius: 5, y: 3)
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
        _ option: QuickActionOption,
        themed: Bool = false
    ) -> some View {
        Button {
            open(option)
        } label: {
            HStack(spacing: 14) {
                if themed {
                    customGridIcon(option)
                } else {
                    HouseMateSymbolView(
                        systemName: option.systemImage,
                        color: option.color,
                        size: 44,
                        symbolSize: 19
                    )
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
                .fill(themed ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color(.secondarySystemBackground)))
                .overlay {
                    if themed {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.62), lineWidth: 0.8)
                    }
                }
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
