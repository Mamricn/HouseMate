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
                    Text(dueDate, format: .dateTime.day().month(.abbreviated))
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
}
#Preview("With Bills") {
    BillRowView(bill: BillModel.mock)
        .padding()
}
