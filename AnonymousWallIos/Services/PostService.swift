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
        wall: String = "campus",
        page: Int = 1,
        limit: Int = 20,
        sort: String = "NEWEST"
    ) async throws -> PostListResponse {
        var components = URLComponents(string: "\(config.fullAPIBaseURL)/posts")
        components?.queryItems = [
            URLQueryItem(name: "wall", value: wall),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort)
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
    
    /// Create a new post
    func createPost(content: String, wall: String = "campus", token: String, userId: String) async throws -> Post {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        let body = CreatePostRequest(content: content, wall: wall)
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
        sort: String = "NEWEST"
    ) async throws -> CommentListResponse {
        var components = URLComponents(string: "\(config.fullAPIBaseURL)/posts/\(postId)/comments")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort)
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
