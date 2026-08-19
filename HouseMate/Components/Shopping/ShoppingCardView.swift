//
//  ShoppingCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct ShoppingCardView: View {
    
    let items: [ShoppingItemModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Shopping List")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            if items.isEmpty {
                
                Text("Shopping list is empty")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
            } else {
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 12) {
                        ForEach(items) { item in
                            ShoppingItemRowView(item: item)
                        }
                    }
                }
                .frame(height: 120)
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

#Preview("With Items") {
    ShoppingCardView(items: ShoppingItemModel.mockList)
        .padding()
}

#Preview("Empty") {
    ShoppingCardView(items: [])
        .padding()
}
