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
        guard let url = URL(string: "\(config.fullAPIBaseURL)/users/me/profile/name") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        let body: [String: String] = [
            "profileName": profileName
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
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
        var components = URLComponents(string: "\(config.fullAPIBaseURL)/users/me/comments")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
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
        var components = URLComponents(string: "\(config.fullAPIBaseURL)/users/me/posts")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        return try await networkClient.performRequest(request)
    }
}
