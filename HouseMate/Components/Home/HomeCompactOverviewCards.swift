//
//  HomeCompactOverviewCards.swift
//  HouseMate
//

import SwiftUI

struct HomeCompactComingUpCard: View {

    let items: [ComingUpItem]
    var onTap: () -> Void = {}

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        HomeCompactCard(title: "Coming Up", systemImage: "calendar", onTap: onTap) {
            if items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(items.prefix(2)) { item in
                        HStack(spacing: 9) {
                            HouseMateSymbolView(
                                systemName: item.systemImage,
                                color: item.kind == .task ? .blue : .purple,
                                size: 32,
                                symbolSize: 13
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                Text(dateText(item.date))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        Label("Nothing planned", systemImage: "checkmark.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func dateText(_ date: Date) -> String {
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}

struct HomeCompactBillsCard: View {

    let bills: [BillModel]
    var onTap: () -> Void = {}

    var body: some View {
        HomeCompactCard(title: "Bills", systemImage: "creditcard", onTap: onTap) {
            if bills.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(bills.prefix(2)) { bill in
                        HStack(spacing: 9) {
                            HouseMateSymbolView(
                                systemName: bill.category.systemImage,
                                color: .blue,
                                size: 32,
                                symbolSize: 13
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(bill.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                Text(bill.amount, format: .currency(code: "GBP"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        Label("No bills due", systemImage: "checkmark.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

private struct HomeCompactCard<Content: View>: View {

    let title: String
    let systemImage: String
    let onTap: () -> Void
    @ViewBuilder let content: Content

    init(
        title: String,
        systemImage: String,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 2)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary.opacity(0.7))
            }

            content

            Spacer(minLength: 0)
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            HapticFeedback.selection()
            onTap()
        }
        .accessibilityAddTraits(.isButton)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 134, alignment: .top)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.55), lineWidth: 1)
                }
        }
    }
}

#Preview {
    HStack(alignment: .top, spacing: 12) {
        HomeCompactComingUpCard(items: [])
        HomeCompactBillsCard(bills: BillModel.mockList)
    }
    .padding()
}
