//
//  HouseholdBoardRowView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct HouseholdBoardRowView: View {
    
    let post: BoardPostModel
    let user: UserModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            Circle()
                .fill(.gray.opacity(0.2))
                .frame(width: 42, height: 42)
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(user.name ?? "Unknown")
                    .font(.headline)
                
                Text(post.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HouseholdBoardRowView(
        post: .mock,
        user: .mock
    )
    .padding()
}
