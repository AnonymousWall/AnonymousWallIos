//
//  PollModels.swift
//  AnonymousWallIos
//
//  Data models for poll-type posts
//

import Foundation

struct PollDTO: Codable {
    let options: [PollOptionDTO]
    let totalVotes: Int
    let userVotedOptionId: UUID?
    let resultsVisible: Bool
}

struct PollOptionDTO: Codable, Identifiable {
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
