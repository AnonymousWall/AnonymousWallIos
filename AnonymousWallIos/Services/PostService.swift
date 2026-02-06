//
//  PostService.swift
//  AnonymousWallIos
//
//  Service for post-related API calls
//

import Foundation

class PostService {
    static let shared = PostService()
    
    private let config = AppConfiguration.shared
    private let networkClient = NetworkClient.shared
    
    private init() {}
    
    // MARK: - Post Operations
    
    /// Fetch list of posts
    func fetchPosts(
        token: String,
        userId: String,
        wall: WallType = .campus,
        page: Int = 1,
        limit: Int = 20,
        sort: SortOrder = .newest
    ) async throws -> PostListResponse {
        var components = URLComponents(string: "\(config.fullAPIBaseURL)/posts")
        components?.queryItems = [
            URLQueryItem(name: "wall", value: wall.rawValue),
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
        
        // Try to decode as PostListResponse with pagination structure
        do {
            return try await networkClient.performRequest(request)
        } catch NetworkError.cancelled {
            // Re-throw cancellation errors without logging
            throw NetworkError.cancelled
        } catch {
            // If backend returns a different structure, try to handle gracefully
            // This can happen if backend hasn't been updated yet
            print("⚠️ Failed to decode PostListResponse: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Create a new post
    func createPost(title: String, content: String, wall: WallType = .campus, token: String, userId: String) async throws -> Post {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        let body = CreatePostRequest(title: title, content: content, wall: wall.rawValue)
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await networkClient.performRequest(request)
    }
    
    /// Toggle like on a post
    func toggleLike(postId: String, token: String, userId: String) async throws -> LikeResponse {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts/\(postId)/likes") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        return try await networkClient.performRequest(request)
    }
    
    /// Hide/delete a post (soft delete)
    func hidePost(postId: String, token: String, userId: String) async throws -> HidePostResponse {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts/\(postId)/hide") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Comment Operations
    
    /// Add a comment to a post
    func addComment(postId: String, text: String, token: String, userId: String) async throws -> Comment {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts/\(postId)/comments") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        let body = CreateCommentRequest(text: text)
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await networkClient.performRequest(request)
    }
    
    /// Get comments for a post
    func getComments(
        postId: String,
        token: String,
        userId: String,
        page: Int = 1,
        limit: Int = 20,
        sort: SortOrder = .newest
    ) async throws -> CommentListResponse {
        var components = URLComponents(string: "\(config.fullAPIBaseURL)/posts/\(postId)/comments")
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
    
    /// Hide/delete a comment (soft delete)
    func hideComment(postId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts/\(postId)/comments/\(commentId)/hide") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        return try await networkClient.performRequest(request)
    }
}
