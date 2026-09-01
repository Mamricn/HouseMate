//
//  MockPollService.swift
//  HouseMate
//

import Foundation

@MainActor
final class MockPollService: PollServiceProtocol {

    private var polls: [PollModel]

    init(polls: [PollModel]) {
        self.polls = polls
    }

    convenience init() {
        self.init(polls: PollModel.mockList)
    }

    func fetchActivePolls(householdID: String, limit: Int) async throws -> [PollModel] {
        Array(
            polls
                .filter { $0.householdId == householdID && $0.status == .active }
                .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
                .prefix(limit)
        )
    }

    func createPoll(_ poll: PollModel) async throws {
        polls.append(poll)
    }

    func vote(pollID: String, householdID: String, userID: String, optionID: String) async throws {
        guard let index = polls.firstIndex(where: {
            $0.pollId == pollID && $0.householdId == householdID
        }) else {
            return
        }

        polls[index].votesByUserId[userID] = optionID
    }

    func closePoll(pollID: String, householdID: String) async throws {
        guard let index = polls.firstIndex(where: {
            $0.pollId == pollID && $0.householdId == householdID
        }) else {
            return
        }

        polls[index].status = .closed
    }

    func deletePoll(pollID: String, householdID: String) async throws {
        polls.removeAll { $0.pollId == pollID && $0.householdId == householdID }
    }
}
