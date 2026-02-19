//
//  Internship.swift
//  AnonymousWallIos
//
//  Model for internship postings
//

import Foundation

struct Internship: Codable, Identifiable, Hashable {
    let id: String
    let company: String
    let role: String
    let salary: String?
    let location: String?
    let description: String?
    let deadline: String?
    let wall: String
    let comments: Int
    let author: Post.Author
    let createdAt: String
    let updatedAt: String

    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Internship, rhs: Internship) -> Bool {
        lhs.id == rhs.id
    }

    /// Create a copy with updated comment count
    func withUpdatedComments(comments: Int) -> Internship {
        return Internship(
            id: self.id,
            company: self.company,
            role: self.role,
            salary: self.salary,
            location: self.location,
            description: self.description,
            deadline: self.deadline,
            wall: self.wall,
            comments: comments,
            author: self.author,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}

struct InternshipListResponse: Codable {
    let data: [Internship]
    let pagination: PostListResponse.Pagination
}

struct CreateInternshipRequest: Codable {
    let company: String
    let role: String
    let salary: String?
    let location: String?
    let description: String?
    let deadline: String?
    let wall: String
}
