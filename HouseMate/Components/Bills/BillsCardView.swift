//
//  BillsCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct BillsCardView: View {

    let bills: [BillModel]

    var showsAddButton: Bool = true
    var onMarkAsPaid: (BillModel) -> Void = { _ in }

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
            Text("Upcoming Bills")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showsAddButton {
                Button {

                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Bills List

    private var billsList: some View {
        List(bills) { bill in
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
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true
                ) {
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
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 180)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.green)

            Text("No upcoming bills")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
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

#Preview("With Bills") {
    BillsCardView(
        bills: BillModel.mockList,
        onMarkAsPaid: { bill in
            print("Mark as paid: \(bill.title)")
        }
    )
    .padding()
}

#Preview("Without Add Button") {
    BillsCardView(
        bills: BillModel.mockList,
        showsAddButton: false,
        onMarkAsPaid: { bill in
            print("Mark as paid: \(bill.title)")
        }
    )
    .padding()
}

#Preview("Empty") {
    BillsCardView(
        bills: [],
        showsAddButton: false
    )
    .padding()
}
