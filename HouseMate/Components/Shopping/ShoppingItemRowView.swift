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
                .foregroundStyle(
                    item.isPurchased
                        ? Color.green
                        : Color.primary
                )
            
            Text(item.name)
                .font(.footnote)
                .strikethrough(item.isPurchased)
                .foregroundStyle(
                    item.isPurchased
                        ? Color.secondary
                        : Color.primary
                )
            
            Spacer()
            
            if item.quantity > 1 {
                Text("x\(item.quantity)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .frame(minHeight: 40)
        .animation(.snappy(duration: 0.25), value: item.isPurchased)
    }
}

#Preview {
    ShoppingItemRowView(item: .mock)
        .padding()
}
