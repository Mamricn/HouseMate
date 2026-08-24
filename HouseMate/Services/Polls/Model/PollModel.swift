//
//  PollModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import Foundation

struct PollModel: Identifiable, Codable, Equatable {

    var id: String {
        pollId
    }

    let pollId: String
    let householdId: String
    let createdAt: Date?

    let createdByUserId: String

    var question: String
    var options: [PollOptionModel]

    // userId: optionId
    var votesByUserId: [String: String]

    var status: PollStatus
    var expiresAt: Date?

    init(
        pollId: String,
        householdId: String,
        createdAt: Date? = nil,
        createdByUserId: String,
        question: String,
        options: [PollOptionModel],
        votesByUserId: [String: String] = [:],
        status: PollStatus = .active,
        expiresAt: Date? = nil
    ) {
        self.pollId = pollId
        self.householdId = householdId
        self.createdAt = createdAt
        self.createdByUserId = createdByUserId
        self.question = question
        self.options = options
        self.votesByUserId = votesByUserId
        self.status = status
        self.expiresAt = expiresAt
    }

    enum CodingKeys: String, CodingKey {
        case pollId = "poll_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case createdByUserId = "created_by_user_id"
        case question
        case options
        case votesByUserId = "votes_by_user_id"
        case status
        case expiresAt = "expires_at"
    }

    var totalVotes: Int {
        votesByUserId.count
    }

    func voteCount(
        for option: PollOptionModel
    ) -> Int {
        votesByUserId.values.filter {
            $0 == option.id
        }.count
    }

    func selectedOptionId(
        for userId: String
    ) -> String? {
        votesByUserId[userId]
    }

    var eventParameters: [String: Any] {
        let dictionary: [String: Any?] = [
            "poll_\(CodingKeys.pollId.rawValue)": pollId,
            "poll_\(CodingKeys.householdId.rawValue)": householdId,
            "poll_\(CodingKeys.createdAt.rawValue)": createdAt,
            "poll_\(CodingKeys.createdByUserId.rawValue)": createdByUserId,
            "poll_\(CodingKeys.question.rawValue)": question,
            "poll_\(CodingKeys.status.rawValue)": status.rawValue,
            "poll_\(CodingKeys.expiresAt.rawValue)": expiresAt,
            "poll_total_votes": totalVotes
        ]

        return dictionary.compactMapValues { $0 }
    }
}

// MARK: - Poll Option

struct PollOptionModel: Identifiable, Codable, Equatable {

    var id: String {
        optionId
    }

    let optionId: String
    var text: String

    init(
        optionId: String,
        text: String
    ) {
        self.optionId = optionId
        self.text = text
    }

    enum CodingKeys: String, CodingKey {
        case optionId = "option_id"
        case text
    }
}

// MARK: - Poll Status

enum PollStatus: String, Codable, CaseIterable {
    case active
    case closed
}

// MARK: - Mock Data

extension PollModel {

    static let mock = PollModel(
        pollId: "poll_1",
        householdId: "house_123",
        createdAt: .now,
        createdByUserId: "1",
        question: "What should we order tonight?",
        options: [
            PollOptionModel(
                optionId: "pizza",
                text: "Pizza"
            ),
            PollOptionModel(
                optionId: "chinese",
                text: "Chinese"
            ),
            PollOptionModel(
                optionId: "burgers",
                text: "Burgers"
            )
        ],
        votesByUserId: [
            "1": "pizza",
            "2": "pizza",
            "3": "chinese"
        ]
    )

    static let mockList: [PollModel] = [
        PollModel(
            pollId: "poll_1",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "1",
            question: "What should we order tonight?",
            options: [
                PollOptionModel(
                    optionId: "pizza",
                    text: "Pizza"
                ),
                PollOptionModel(
                    optionId: "chinese",
                    text: "Chinese"
                ),
                PollOptionModel(
                    optionId: "burgers",
                    text: "Burgers"
                )
            ],
            votesByUserId: [
                "1": "pizza",
                "2": "pizza",
                "3": "chinese"
            ]
        ),

        PollModel(
            pollId: "poll_2",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "2",
            question: "Which day for movie night?",
            options: [
                PollOptionModel(
                    optionId: "friday",
                    text: "Friday"
                ),
                PollOptionModel(
                    optionId: "saturday",
                    text: "Saturday"
                ),
                PollOptionModel(
                    optionId: "sunday",
                    text: "Sunday"
                )
            ],
            votesByUserId: [
                "1": "saturday",
                "2": "friday"
            ]
        ),

        PollModel(
            pollId: "poll_3",
            householdId: "house_123",
            createdAt: .now,
            createdByUserId: "3",
            question: "Which room should we decorate next?",
            options: [
                PollOptionModel(
                    optionId: "living_room",
                    text: "Living room"
                ),
                PollOptionModel(
                    optionId: "kitchen",
                    text: "Kitchen"
                ),
                PollOptionModel(
                    optionId: "hallway",
                    text: "Hallway"
                )
            ],
            votesByUserId: [:]
        )
    ]
}
