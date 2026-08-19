//
//  BillsCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct BillsCardView: View {

    let bills: [BillModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Upcoming Bills")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {

                } label: {
                    Image(systemName: "plus")
                }
            }

            if bills.isEmpty {

                Text("No upcoming bills")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            } else {

                ScrollView(.vertical) {
                    LazyVStack(spacing: 12) {
                        ForEach(bills) { bill in
                            BillRowView(bill: bill)
                        }
                    }
                }
                .frame(height: 150)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding()
        .background {
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
                .stroke(.white.opacity(0.85), lineWidth: 1)
            }
        }
    }
}

#Preview("With Bills") {
    BillsCardView(bills: BillModel.mockList)
        .padding()
}

#Preview("Empty") {
    BillsCardView(bills: [])
        .padding()
}
