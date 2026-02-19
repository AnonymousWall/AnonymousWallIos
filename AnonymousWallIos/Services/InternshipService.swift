//
//  InternshipService.swift
//  AnonymousWallIos
//
//  Service for internship-related API calls
//

import Foundation

class InternshipService: InternshipServiceProtocol {
    static let shared: InternshipServiceProtocol = InternshipService()

    private let networkClient = NetworkClient.shared

    private init() {}

    // MARK: - Internship Operations

    func fetchInternships(
        token: String,
        userId: String,
        wall: WallType = .campus,
        page: Int = 1,
        limit: Int = 20,
        sortBy: FeedSortOrder = .newest
    ) async throws -> InternshipListResponse {
        let queryItems = [
            URLQueryItem(name: "wall", value: wall.rawValue),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy.rawValue)
        ]

        let request = try APIRequestBuilder()
            .setPath("/internships")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func getInternship(
        internshipId: String,
        token: String,
        userId: String
    ) async throws -> Internship {
        let request = try APIRequestBuilder()
            .setPath("/internships/\(internshipId)")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func createInternship(
        company: String,
        role: String,
        salary: String?,
        location: String?,
        description: String?,
        deadline: String?,
        wall: WallType = .campus,
        token: String,
        userId: String
    ) async throws -> Internship {
        let body = CreateInternshipRequest(
            company: company,
            role: role,
            salary: salary,
            location: location,
            description: description,
            deadline: deadline,
            wall: wall.rawValue
        )

        let request = try APIRequestBuilder()
            .setPath("/internships")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func hideInternship(
        internshipId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/internships/\(internshipId)/hide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func unhideInternship(
        internshipId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/internships/\(internshipId)/unhide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    // MARK: - Comment Operations

    func addComment(
        internshipId: String,
        text: String,
        token: String,
        userId: String
    ) async throws -> Comment {
        let body = CreateCommentRequest(text: text)

        let request = try APIRequestBuilder()
            .setPath("/internships/\(internshipId)/comments")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func getComments(
        internshipId: String,
        token: String,
        userId: String,
        page: Int = 1,
        limit: Int = 20,
        sort: SortOrder = .newest
    ) async throws -> CommentListResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]

        let request = try APIRequestBuilder()
            .setPath("/internships/\(internshipId)/comments")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func hideComment(
        internshipId: String,
        commentId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/internships/\(internshipId)/comments/\(commentId)/hide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func unhideComment(
        internshipId: String,
        commentId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/internships/\(internshipId)/comments/\(commentId)/unhide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }
}
