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
        HStack(alignment: .top, spacing: 10) {
            
            CachedProfileImage(
                urlString: user.profileImageUrl,
                displayName: user.name ?? "Housemate",
                size: 32
            )
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(user.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(post.text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HouseholdBoardRowView(
        post: .mock,
        user: .mock
    )
    .padding()
}
