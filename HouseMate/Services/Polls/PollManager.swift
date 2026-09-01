//
//  PollManager.swift
//  HouseMate
//

import Foundation

@Observable
@MainActor
final class PollManager {

    private let service: any PollServiceProtocol
    private var observation: ServiceObservation?

    private(set) var polls: [PollModel] = []

    init(service: any PollServiceProtocol) {
        self.service = service
    }

    func fetchPolls(householdID: String) async throws {
        observation?.cancel()
        observation = service.observeActivePolls(householdID: householdID, limit: 20) { [weak self] result in
            if case .success(let polls) = result {
                self?.setActivePolls(polls)
            }
        }

        if observation == nil {
            setActivePolls(try await service.fetchActivePolls(householdID: householdID, limit: 20))
        }
    }

    func createPoll(_ poll: PollModel) async throws {
        try await service.createPoll(poll)
        if !polls.contains(where: { $0.pollId == poll.pollId }) {
            polls.insert(poll, at: 0)
        }
        polls = Array(polls.prefix(20))
    }

    func vote(in poll: PollModel, option: PollOptionModel, userID: String) async throws {
        guard poll.status == .active,
              poll.selectedOptionId(for: userID) != option.optionId,
              poll.options.contains(where: { $0.optionId == option.optionId }) else {
            return
        }

        try await service.vote(
            pollID: poll.pollId,
            householdID: poll.householdId,
            userID: userID,
            optionID: option.optionId
        )

        guard let index = polls.firstIndex(where: { $0.pollId == poll.pollId }) else {
            return
        }

        polls[index].votesByUserId[userID] = option.optionId
    }

    func closePoll(_ poll: PollModel, currentUserID: String) async throws {
        guard poll.createdByUserId == currentUserID else {
            return
        }

        try await service.closePoll(pollID: poll.pollId, householdID: poll.householdId)
        polls.removeAll { $0.pollId == poll.pollId }
    }

    func deletePoll(_ poll: PollModel, currentUserID: String) async throws {
        guard poll.createdByUserId == currentUserID else {
            return
        }

        try await service.deletePoll(pollID: poll.pollId, householdID: poll.householdId)
        polls.removeAll { $0.pollId == poll.pollId }
    }

    func clearPolls() {
        observation?.cancel()
        observation = nil
        polls = []
    }

    private func setActivePolls(_ fetchedPolls: [PollModel]) {
        let now = Date.now
        polls = fetchedPolls.filter { $0.expiresAt.map { $0 > now } ?? true }
    }
}
