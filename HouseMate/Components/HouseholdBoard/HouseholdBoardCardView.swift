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

    let currentUserId: String

    var showsAddButton: Bool = true

    var onAdd: () -> Void = {}
    var onDelete: (BoardPostModel) -> Void = { _ in }
    var canLoadMore: Bool = false
    var isLoadingMore: Bool = false
    var onLoadMore: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if posts.isEmpty {
                emptyState
            } else {
                postsList
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
            Text("Household Board")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showsAddButton {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Posts List

    private var postsList: some View {
        List {
            ForEach(sortedPosts) { post in
                if let user = user(for: post) {
                    HouseholdBoardRowView(
                        post: post,
                        user: user
                    )
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
                    .onAppear {
                        if post.id == sortedPosts.last?.id,
                           canLoadMore,
                           !isLoadingMore {
                            onLoadMore()
                        }
                    }

                    // Użytkownik może usunąć tylko swój post
                    .swipeActions(
                        edge: .leading,
                        allowsFullSwipe: false
                    ) {
                        if post.createdByUserId == currentUserId {
                            deleteButton(for: post)
                        }
                    }
                }
            }

            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 180)
    }

    // MARK: - Delete Action

    private func deleteButton(
        for post: BoardPostModel
    ) -> some View {
        Button(role: .destructive) {
            onDelete(post)
        } label: {
            Label(
                "Delete",
                systemImage: "trash.fill"
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.bubble")
                .font(.system(size: 28))
                .foregroundStyle(.blue)

            Text("No posts yet")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Share something with your housemates.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }

    // MARK: - Helpers

    private var sortedPosts: [BoardPostModel] {
        posts.sorted {
            ($0.createdAt ?? .distantPast)
                > ($1.createdAt ?? .distantPast)
        }
    }

    private func user(
        for post: BoardPostModel
    ) -> UserModel? {
        users.first {
            $0.userId == post.createdByUserId
        }
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

#Preview("With Posts") {
    HouseholdBoardCardView(
        posts: BoardPostModel.mockList,
        users: UserModel.mockList,
        currentUserId: "1",
        showsAddButton: true,
        onAdd: {
            print("Add post")
        },
        onDelete: { post in
            print("Delete post: \(post.text)")
        }
    )
    .padding()
}

#Preview("Empty") {
    HouseholdBoardCardView(
        posts: [],
        users: UserModel.mockList,
        currentUserId: "1"
    )
    .padding()
}
