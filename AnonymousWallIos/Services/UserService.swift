//
//  UserService.swift
//  AnonymousWallIos
//
//  User service for API calls related to user profile and content
//

import Foundation

class UserService: UserServiceProtocol {
    static let shared = UserService()
    
    private let config = AppConfiguration.shared
    private let networkClient = NetworkClient.shared
    
    private init() {}
    
    // MARK: - Profile Management
    
    /// Update user's profile name
    func updateProfileName(profileName: String, token: String, userId: String) async throws -> User {
        let body: [String: String] = [
            "profileName": profileName
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/users/me/profile/name")
            .setMethod(.PATCH)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - User Content Operations
    
    /// Get user's own comments
    func getUserComments(
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
            .setPath("/users/me/comments")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Get user's own posts
    func getUserPosts(
        token: String,
        userId: String,
        page: Int = 1,
        limit: Int = 20,
        sort: SortOrder = .newest
    ) async throws -> PostListResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/users/me/posts")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Get user's own internship postings
    func getUserInternships(
        token: String,
        userId: String,
        page: Int = 1,
        limit: Int = 20,
        sort: SortOrder = .newest
    ) async throws -> InternshipListResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/users/me/internships")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Get user's own marketplace items
    func getUserMarketplaces(
        token: String,
        userId: String,
        page: Int = 1,
        limit: Int = 20,
        sort: SortOrder = .newest
    ) async throws -> MarketplaceListResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/users/me/marketplaces")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
}
