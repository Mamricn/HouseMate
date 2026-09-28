import Foundation
import Testing
@testable import HouseMate

@Suite("HouseholdBoardManager — posts and pagination")
struct HouseholdBoardManagerTests {

    @Test("Pagination loads all posts once and preserves their order")
    @MainActor
    func loadsPostsWithoutDuplicates() async throws {
        let householdID = "house-board"
        let posts = (0..<25).map { index in
            BoardPostModel(
                postId: String(format: "post-%02d", index),
                householdId: householdID,
                createdAt: Date(timeIntervalSince1970: Double(index)),
                createdByUserId: "creator",
                text: "Post \(index)"
            )
        }
        let manager = HouseholdBoardManager(
            service: MockHouseholdBoardService(posts: posts)
        )

        try await manager.fetchInitialPosts(householdID: householdID)
        #expect(manager.posts.count == 20)
        #expect(manager.canLoadMore)

        try await manager.loadMorePosts()
        #expect(manager.posts.count == 25)
        #expect(Set(manager.posts.map(\.postId)).count == 25)
        #expect(!manager.canLoadMore)
    }

    @Test("Only a post author can delete their post")
    @MainActor
    func onlyAuthorCanDeletePost() async throws {
        let post = BoardPostModel(
            postId: "post",
            householdId: "house-board",
            createdAt: .now,
            createdByUserId: "author",
            text: "Dinner at seven"
        )
        let manager = HouseholdBoardManager(
            service: MockHouseholdBoardService(posts: [post])
        )
        try await manager.fetchInitialPosts(householdID: post.householdId)

        try await manager.deletePost(post, currentUserID: "other-member")
        #expect(manager.posts == [post])

        try await manager.deletePost(post, currentUserID: "author")
        #expect(manager.posts.isEmpty)
    }
}
