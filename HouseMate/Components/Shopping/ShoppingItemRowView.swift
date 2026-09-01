//
//  ShoppingItemRowView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct ShoppingItemRowView: View {
    
    let item: ShoppingItemModel
    
    var body: some View {
        HStack(spacing: 12) {
            
            Image(systemName: item.isPurchased
                  ? "checkmark.circle.fill"
                  : "circle")
                .font(.title3)
            
            Text(item.name)
                .font(.footnote)
            
            Spacer()
            
            if item.quantity > 1 {
                Text("x\(item.quantity)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .frame(minHeight: 40)
    }
}

#Preview {
    ShoppingItemRowView(item: .mock)
        .padding()
}
