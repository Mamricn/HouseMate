//
//  FirebaseHouseholdBoardService.swift
//  HouseMate
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirebaseHouseholdBoardService: HouseholdBoardServiceProtocol {

    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func fetchPosts(householdID: String, after cursor: BoardPostCursor?, limit: Int) async throws -> BoardPostPage {
        var query: Query = postsCollection(householdID: householdID)
            .order(by: "created_at", descending: true)
            .order(by: FieldPath.documentID(), descending: true)
            .limit(to: limit)

        if let cursor {
            query = query.start(after: [cursor.createdAt, cursor.postID])
        }

        let snapshot = try await query.getDocuments()
        let posts = try snapshot.documents.map { document in
            try Firestore.Decoder().decode(BoardPostModel.self, from: document.data())
        }

        let nextCursor: BoardPostCursor?

        if let lastPost = posts.last,
           let createdAt = lastPost.createdAt {
            nextCursor = BoardPostCursor(createdAt: createdAt, postID: lastPost.postId)
        } else {
            nextCursor = nil
        }

        return BoardPostPage(
            posts: posts,
            nextCursor: nextCursor,
            hasMore: posts.count == limit
        )
    }

    func observeInitialPosts(householdID: String, limit: Int, onChange: @escaping (Result<BoardPostPage, Error>) -> Void) -> ServiceObservation? {
        let listener = postsCollection(householdID: householdID)
            .order(by: "created_at", descending: true)
            .order(by: FieldPath.documentID(), descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                do {
                    let posts = try snapshot?.documents.map {
                        try Firestore.Decoder().decode(BoardPostModel.self, from: $0.data())
                    } ?? []
                    let nextCursor = posts.last.flatMap { post in
                        post.createdAt.map { BoardPostCursor(createdAt: $0, postID: post.postId) }
                    }
                    onChange(.success(BoardPostPage(posts: posts, nextCursor: nextCursor, hasMore: posts.count == limit)))
                } catch {
                    onChange(.failure(error))
                }
            }

        return ServiceObservation(cancellation: listener.remove)
    }

    func createPost(_ post: BoardPostModel) async throws {
        let data = try Firestore.Encoder().encode(post)

        try await postsCollection(householdID: post.householdId)
            .document(post.postId)
            .setData(data)
    }

    func deletePost(postID: String, householdID: String) async throws {
        try await postsCollection(householdID: householdID)
            .document(postID)
            .delete()
    }

    private func postsCollection(householdID: String) -> CollectionReference {
        database
            .collection("households")
            .document(householdID)
            .collection("board_posts")
    }
}
