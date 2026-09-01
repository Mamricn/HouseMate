//
//  HouseholdBoardManager.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class HouseholdBoardManager {

    private let service: any HouseholdBoardServiceProtocol
    private var cursor: BoardPostCursor?
    private var householdID: String?
    private var observation: ServiceObservation?
    private var initialPagePostIDs: Set<String> = []

    private(set) var posts: [BoardPostModel] = []
    private(set) var isLoading = false
    private(set) var canLoadMore = true

    init(service: any HouseholdBoardServiceProtocol) {
        self.service = service
    }

    func fetchInitialPosts(householdID: String) async throws {
        guard !isLoading else {
            return
        }

        self.householdID = householdID
        cursor = nil
        canLoadMore = true
        isLoading = true
        defer { isLoading = false }

        observation?.cancel()
        observation = service.observeInitialPosts(householdID: householdID, limit: 20) { [weak self] result in
            guard let self, case .success(let page) = result else {
                return
            }

            let olderPosts = self.posts.filter { !self.initialPagePostIDs.contains($0.postId) }
            self.initialPagePostIDs = Set(page.posts.map(\.postId))
            self.posts = page.posts + olderPosts.filter { !self.initialPagePostIDs.contains($0.postId) }

            if olderPosts.isEmpty {
                self.cursor = page.nextCursor
                self.canLoadMore = page.hasMore
            }
        }

        if observation == nil {
            let page = try await service.fetchPosts(householdID: householdID, after: nil, limit: 20)
            posts = page.posts
            initialPagePostIDs = Set(page.posts.map(\.postId))
            cursor = page.nextCursor
            canLoadMore = page.hasMore
        }
    }

    func loadMorePosts() async throws {
        guard let householdID,
              canLoadMore,
              !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        let page = try await service.fetchPosts(householdID: householdID, after: cursor, limit: 20)
        let existingIDs = Set(posts.map(\.postId))
        posts.append(contentsOf: page.posts.filter { !existingIDs.contains($0.postId) })
        cursor = page.nextCursor
        canLoadMore = page.hasMore
    }

    func createPost(_ post: BoardPostModel) async throws {
        try await service.createPost(post)
        if !posts.contains(where: { $0.postId == post.postId }) {
            posts.insert(post, at: 0)
        }
    }

    func deletePost(_ post: BoardPostModel, currentUserID: String) async throws {
        guard post.createdByUserId == currentUserID else {
            return
        }

        try await service.deletePost(postID: post.postId, householdID: post.householdId)
        posts.removeAll { $0.postId == post.postId }
    }

    func clearPosts() {
        observation?.cancel()
        observation = nil
        posts = []
        initialPagePostIDs = []
        cursor = nil
        householdID = nil
        canLoadMore = true
        isLoading = false
    }
}
