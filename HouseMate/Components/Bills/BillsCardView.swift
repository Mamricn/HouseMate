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
        List {
            ForEach(bills) { bill in
                BillRowView(bill: bill)
                    .listRowInsets(
                        EdgeInsets(
                            top: 4,
                            leading: 0,
                            bottom: 4,
                            trailing: 0
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // Delete po lewej stronie
                    .swipeActions(
                        edge: .leading,
                        allowsFullSwipe: false
                    ) {
                        if onDelete != nil {
                            deleteButton(for: bill)
                        }
                    }

                    // Mark as Paid po prawej stronie
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: true
                    ) {
                        if bill.status != .paid {
                            markAsPaidButton(for: bill)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 180)
    }

    // MARK: - Swipe Action

    private func markAsPaidButton(
        for bill: BillModel
    ) -> some View {
        Button {
            onMarkAsPaid(bill)
        } label: {
            Label(
                "Mark as Paid",
                systemImage: "checkmark.circle.fill"
            )
        }
        .tint(.green)
    }
    
    private func deleteButton(
        for bill: BillModel
    ) -> some View {
        Button(role: .destructive) {
            onDelete?(bill)
        } label: {
            Label(
                "Delete",
                systemImage: "trash.fill"
            )
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
        .fill(.ultraThickMaterial)
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
