//
//  MockHouseholdBoardService.swift
//  HouseMate
//

import Foundation

@MainActor
final class MockHouseholdBoardService: HouseholdBoardServiceProtocol {

    private var posts: [BoardPostModel]

    init(posts: [BoardPostModel]) {
        self.posts = posts
    }

    convenience init() {
        self.init(posts: BoardPostModel.mockList)
    }

    func fetchPosts(householdID: String, after cursor: BoardPostCursor?, limit: Int) async throws -> BoardPostPage {
        let sortedPosts = posts
            .filter { $0.householdId == householdID }
            .sorted(by: isBefore)

        let startIndex: Int

        if let cursor,
           let cursorIndex = sortedPosts.firstIndex(where: { $0.postId == cursor.postID }) {
            startIndex = sortedPosts.index(after: cursorIndex)
        } else {
            startIndex = sortedPosts.startIndex
        }

        let pagePosts = Array(sortedPosts.dropFirst(startIndex).prefix(limit))
        let nextCursor = makeCursor(from: pagePosts.last)

        return BoardPostPage(
            posts: pagePosts,
            nextCursor: nextCursor,
            hasMore: startIndex + pagePosts.count < sortedPosts.count
        )
    }

    func createPost(_ post: BoardPostModel) async throws {
        posts.append(post)
    }

    func deletePost(postID: String, householdID: String) async throws {
        posts.removeAll { $0.postId == postID && $0.householdId == householdID }
    }

    private func isBefore(_ firstPost: BoardPostModel, _ secondPost: BoardPostModel) -> Bool {
        let firstDate = firstPost.createdAt ?? .distantPast
        let secondDate = secondPost.createdAt ?? .distantPast

        if firstDate == secondDate {
            return firstPost.postId > secondPost.postId
        }

        return firstDate > secondDate
    }

    private func makeCursor(from post: BoardPostModel?) -> BoardPostCursor? {
        guard let post,
              let createdAt = post.createdAt else {
            return nil
        }

        return BoardPostCursor(createdAt: createdAt, postID: post.postId)
    }
}
