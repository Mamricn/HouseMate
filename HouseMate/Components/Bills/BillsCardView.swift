//
//  BillsCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct BillsCardView: View {

    let bills: [BillModel]

    var title: String = "Upcoming Bills"
    var showsAddButton: Bool = true
    var usesThinMaterial: Bool = true

    var onAdd: () -> Void = {}
    var onMarkAsPaid: (BillModel) -> Void = { _ in }
    var onDelete: ((BillModel) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if bills.isEmpty {
                emptyState
            } else {
                billsList
            }
        }
        .padding()
        .background {
            cardBackground
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showsAddButton {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Bills List

    private var billsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(bills) { bill in
                    HouseMateSwipeRow(
                        leadingAction: deleteAction(for: bill),
                        trailingAction: paidAction(for: bill)
                    ) {
                        BillRowView(bill: bill)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 180)
    }

    private func deleteAction(for bill: BillModel) -> HouseMateSwipeAction? {
        guard onDelete != nil else { return nil }

        return HouseMateSwipeAction(
            accessibilityLabel: "Delete \(bill.title)",
            systemImage: "trash.fill",
            color: .red
        ) {
            onDelete?(bill)
        }
    }

    private func paidAction(for bill: BillModel) -> HouseMateSwipeAction? {
        guard bill.status != .paid else { return nil }

        return HouseMateSwipeAction(
            accessibilityLabel: "Mark \(bill.title) as paid",
            systemImage: "checkmark",
            color: .green
        ) {
            onMarkAsPaid(bill)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green)

            Text(emptyStateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var emptyStateText: String {
        title == "All Bills"
            ? "No bills yet"
            : "No upcoming bills"
    }

    // MARK: - Background

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 24,
            style: .continuous
        )
        .fill(usesThinMaterial ? Material.ultraThin : Material.ultraThick)
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                .white.opacity(0.35),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Previews

#Preview("Upcoming Bills") {
    BillsCardView(
        bills: BillModel.mockList,
        title: "Upcoming Bills",
        showsAddButton: false,
        onMarkAsPaid: { bill in
            print("Mark as paid: \(bill.title)")
        }
    )
    .padding()
}

#Preview("All Bills") {
    BillsCardView(
        bills: BillModel.mockList,
        title: "All Bills",
        showsAddButton: true,
        onAdd: {
            print("Add bill")
        },
        onMarkAsPaid: { bill in
            print("Mark as paid: \(bill.title)")
        }
    )
    .padding()
}

#Preview("Empty") {
    BillsCardView(
        bills: [],
        title: "All Bills",
        showsAddButton: true
    )
    .padding()
}
