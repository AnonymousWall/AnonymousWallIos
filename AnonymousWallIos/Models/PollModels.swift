//
//  PollModels.swift
//  AnonymousWallIos
//
//  Data models for poll-type posts
//

import Foundation

struct PollDTO: Codable, Equatable {
    let options: [PollOptionDTO]
    let totalVotes: Int
    let userVotedOptionId: UUID?
    let resultsVisible: Bool
    let isClosed: Bool

    enum CodingKeys: String, CodingKey {
        case options, totalVotes, userVotedOptionId, resultsVisible, isClosed
    }

    init(
        options: [PollOptionDTO],
        totalVotes: Int,
        userVotedOptionId: UUID?,
        resultsVisible: Bool,
        isClosed: Bool = false
    ) {
        self.options = options
        self.totalVotes = totalVotes
        self.userVotedOptionId = userVotedOptionId
        self.resultsVisible = resultsVisible
        self.isClosed = isClosed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        options = try container.decode([PollOptionDTO].self, forKey: .options)
        totalVotes = try container.decode(Int.self, forKey: .totalVotes)
        userVotedOptionId = try container.decodeIfPresent(UUID.self, forKey: .userVotedOptionId)
        resultsVisible = try container.decode(Bool.self, forKey: .resultsVisible)
        isClosed = try container.decodeIfPresent(Bool.self, forKey: .isClosed) ?? false
    }
}

struct PollOptionDTO: Codable, Identifiable, Equatable {
    let id: UUID
    let optionText: String
    let displayOrder: Int
    /// nil when results are not yet visible
    let voteCount: Int?
    /// nil when results are not yet visible
    let percentage: Double?
}

struct PollVoteRequest: Codable {
    let optionId: UUID
}
