//
//  HouseholdBoardServiceProtocol.swift
//  HouseMate
//

import Foundation

struct BoardPostCursor: Equatable {
    let createdAt: Date
    let postID: String
}

struct BoardPostPage {
    let posts: [BoardPostModel]
    let nextCursor: BoardPostCursor?
    let hasMore: Bool
}

@MainActor
protocol HouseholdBoardServiceProtocol: AnyObject {

    func fetchPosts(householdID: String, after cursor: BoardPostCursor?, limit: Int) async throws -> BoardPostPage

    func observeInitialPosts(householdID: String, limit: Int, onChange: @escaping (Result<BoardPostPage, Error>) -> Void) -> ServiceObservation?

    func createPost(_ post: BoardPostModel) async throws

    func deletePost(postID: String, householdID: String) async throws
}

extension HouseholdBoardServiceProtocol {

    func observeInitialPosts(householdID: String, limit: Int, onChange: @escaping (Result<BoardPostPage, Error>) -> Void) -> ServiceObservation? {
        nil
    }
}
