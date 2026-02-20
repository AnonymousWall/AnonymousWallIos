//
//  UserServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for user service operations
//

import Foundation

protocol UserServiceProtocol {
    // MARK: - Profile Management
    
    /// Update user's profile name
    func updateProfileName(profileName: String, token: String, userId: String) async throws -> User
    
    // MARK: - User Content Operations
    
    /// Get user's own comments
    func getUserComments(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse
    
    /// Get user's own posts
    func getUserPosts(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> PostListResponse
    
    /// Get user's own internship postings
    func getUserInternships(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> InternshipListResponse
    
    /// Get user's own marketplace items
    func getUserMarketplaces(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> MarketplaceListResponse
}
