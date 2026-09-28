import Foundation
import Testing
@testable import HouseMate

@Suite("PollManager — voting and poll ownership")
struct PollManagerTests {

    @Test("Voting records a choice and removing the vote clears it")
    @MainActor
    func recordsAndRemovesVote() async throws {
        let poll = makePoll()
        let manager = PollManager(service: MockPollService(polls: [poll]))
        try await manager.fetchPolls(householdID: poll.householdId)
        let option = try #require(poll.options.first)

        try await manager.vote(in: poll, option: option, userID: "member")
        #expect(manager.polls.first?.selectedOptionId(for: "member") == option.optionId)

        let updatedPoll = try #require(manager.polls.first)
        try await manager.removeVote(in: updatedPoll, userID: "member")
        #expect(manager.polls.first?.selectedOptionId(for: "member") == nil)
    }

    @Test("Only the poll creator can close it")
    @MainActor
    func onlyCreatorCanClosePoll() async throws {
        let poll = makePoll()
        let manager = PollManager(service: MockPollService(polls: [poll]))
        try await manager.fetchPolls(householdID: poll.householdId)

        try await manager.closePoll(poll, currentUserID: "other-member")
        #expect(manager.polls.count == 1)

        try await manager.closePoll(poll, currentUserID: poll.createdByUserId)
        #expect(manager.polls.isEmpty)
    }

    @Test("Expired polls are hidden from the active poll list")
    @MainActor
    func hidesExpiredPolls() async throws {
        let active = makePoll(id: "active")
        let expired = makePoll(
            id: "expired",
            expiresAt: .now.addingTimeInterval(-60)
        )
        let manager = PollManager(service: MockPollService(polls: [active, expired]))

        try await manager.fetchPolls(householdID: active.householdId)

        #expect(manager.polls.map(\.pollId) == [active.pollId])
    }
}

private func makePoll(
    id: String = "poll",
    expiresAt: Date? = .now.addingTimeInterval(3_600)
) -> PollModel {
    PollModel(
        pollId: id,
        householdId: "house-polls",
        createdAt: .now,
        createdByUserId: "creator",
        question: "What should we cook?",
        options: [
            PollOptionModel(optionId: "pizza", text: "Pizza"),
            PollOptionModel(optionId: "pasta", text: "Pasta")
        ],
        expiresAt: expiresAt
    )
}
