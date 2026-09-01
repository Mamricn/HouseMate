//
//  PollServiceProtocol.swift
//  HouseMate
//

import Foundation

@MainActor
protocol PollServiceProtocol: AnyObject {

    func fetchActivePolls(householdID: String, limit: Int) async throws -> [PollModel]

    func observeActivePolls(householdID: String, limit: Int, onChange: @escaping (Result<[PollModel], Error>) -> Void) -> ServiceObservation?

    func createPoll(_ poll: PollModel) async throws

    func vote(pollID: String, householdID: String, userID: String, optionID: String) async throws

    func closePoll(pollID: String, householdID: String) async throws

    func deletePoll(pollID: String, householdID: String) async throws
}

extension PollServiceProtocol {

    func observeActivePolls(householdID: String, limit: Int, onChange: @escaping (Result<[PollModel], Error>) -> Void) -> ServiceObservation? {
        nil
    }
}
