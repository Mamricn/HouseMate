//
//  BillRowView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct BillRowView: View {
    
    let bill: BillModel
    
    var body: some View {
        HStack(spacing: 12) {
            
            Image(systemName: bill.category.systemImage)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(.thinMaterial)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let dueDate = bill.dueDate {
                    HStack(spacing: 6) {
                        Text(dueDate, format: .dateTime.day().month(.abbreviated))

                        if bill.status == .paid {
                            statusLabel(title: "Paid", color: .green)
                        } else if bill.status == .overdue {
                            statusLabel(title: "Overdue", color: .red)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(bill.amount, format: .currency(code: "GBP"))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    private func statusLabel(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
#Preview("With Bills") {
    BillRowView(bill: BillModel.mock)
        .padding()
}
