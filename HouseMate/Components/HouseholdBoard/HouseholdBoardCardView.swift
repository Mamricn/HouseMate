//
//  HouseholdBoardCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct HouseholdBoardCardView: View {
    
    let posts: [BoardPostModel]
    let users: [UserModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Household Board")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            if posts.isEmpty {
                Text("No posts yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.vertical) {
                      LazyVStack(alignment: .leading, spacing: 12) {
                          ForEach(posts) { post in
                              if let user = users.first(where: {
                                  $0.userId == post.createdByUserId
                              }) {
                                  HouseholdBoardRowView(
                                      post: post,
                                      user: user
                                  )
                              }
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

#Preview {
    HouseholdBoardCardView(
        posts: BoardPostModel.mockList,
        users: UserModel.mockList
    )
    .padding()
}
