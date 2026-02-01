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
    func fetchPosts(token: String, userId: String, page: Int = 1, limit: Int = 20) async throws -> [Post] {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts?page=\(page)&limit=\(limit)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        // Try to decode as PostListResponse first, fall back to array
        do {
            let listResponse: PostListResponse = try await networkClient.performRequest(request)
            return listResponse.posts
        } catch {
            // Fallback to array
            let posts: [Post] = try await networkClient.performRequest(request)
            return posts
        }
    }
    
    /// Create a new post
    func createPost(content: String, token: String, userId: String) async throws -> Post {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let body = CreatePostRequest(content: content)
        request.httpBody = try JSONEncoder().encode(body)
        
        // Try to decode as CreatePostResponse first, fall back to Post
        do {
            let createResponse: CreatePostResponse = try await networkClient.performRequest(request)
            return createResponse.post
        } catch {
            // Fallback to Post
            let post: Post = try await networkClient.performRequest(request)
            return post
        }
    }
    
    /// Delete a post
    func deletePost(postId: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts/\(postId)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        try await networkClient.performRequestWithoutResponse(request)
    }
    
    /// Like a post
    func likePost(postId: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts/\(postId)/like") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        try await networkClient.performRequestWithoutResponse(request)
    }
    
    /// Unlike a post
    func unlikePost(postId: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(config.fullAPIBaseURL)/posts/\(postId)/like") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        try await networkClient.performRequestWithoutResponse(request)
    }
}
