//
//  InternshipServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for internship service operations
//

import Foundation

protocol InternshipServiceProtocol {
    // MARK: - Internship Operations

    func fetchInternships(
        token: String,
        userId: String,
        wall: WallType,
        page: Int,
        limit: Int,
        sortBy: FeedSortOrder
    ) async throws -> InternshipListResponse

    func getInternship(
        internshipId: String,
        token: String,
        userId: String
    ) async throws -> Internship

    func createInternship(
        company: String,
        role: String,
        salary: String?,
        location: String?,
        description: String?,
        deadline: String?,
        wall: WallType,
        token: String,
        userId: String
    ) async throws -> Internship

    func hideInternship(internshipId: String, token: String, userId: String) async throws -> HidePostResponse
    func unhideInternship(internshipId: String, token: String, userId: String) async throws -> HidePostResponse

    // MARK: - Comment Operations

    func addComment(internshipId: String, text: String, token: String, userId: String) async throws -> Comment

    func getComments(
        internshipId: String,
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse

    func hideComment(internshipId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse
    func unhideComment(internshipId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse
}
