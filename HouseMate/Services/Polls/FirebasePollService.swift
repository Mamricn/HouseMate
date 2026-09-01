//
//  FirebasePollService.swift
//  HouseMate
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirebasePollService: PollServiceProtocol {

    private let database: Firestore

    init(database: Firestore = Firestore.firestore()) {
        self.database = database
    }

    func fetchActivePolls(householdID: String, limit: Int) async throws -> [PollModel] {
        let snapshot = try await pollsCollection(householdID: householdID)
            .whereField("status", isEqualTo: PollStatus.active.rawValue)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents
            .map { document in
                try Firestore.Decoder().decode(PollModel.self, from: document.data())
            }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    func observeActivePolls(householdID: String, limit: Int, onChange: @escaping (Result<[PollModel], Error>) -> Void) -> ServiceObservation? {
        let listener = pollsCollection(householdID: householdID)
            .whereField("status", isEqualTo: PollStatus.active.rawValue)
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                do {
                    let polls = try snapshot?.documents.map {
                        try Firestore.Decoder().decode(PollModel.self, from: $0.data())
                    } ?? []
                    onChange(.success(polls.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }))
                } catch {
                    onChange(.failure(error))
                }
            }

        return ServiceObservation(cancellation: listener.remove)
    }

    func createPoll(_ poll: PollModel) async throws {
        let data = try Firestore.Encoder().encode(poll)

        try await pollsCollection(householdID: poll.householdId)
            .document(poll.pollId)
            .setData(data)
    }

    func vote(pollID: String, householdID: String, userID: String, optionID: String) async throws {
        try await pollsCollection(householdID: householdID)
            .document(pollID)
            .updateData([
                "votes_by_user_id.\(userID)": optionID
            ])
    }

    func closePoll(pollID: String, householdID: String) async throws {
        try await pollsCollection(householdID: householdID)
            .document(pollID)
            .updateData([
                "status": PollStatus.closed.rawValue
            ])
    }

    func deletePoll(pollID: String, householdID: String) async throws {
        try await pollsCollection(householdID: householdID)
            .document(pollID)
            .delete()
    }

    private func pollsCollection(householdID: String) -> CollectionReference {
        database
            .collection("households")
            .document(householdID)
            .collection("polls")
    }
}
