//
//  PostService.swift
//  AnonymousWallIos
//
//  Service for post-related API calls
//

import Foundation

class PostService: PostServiceProtocol {
    static let shared: PostServiceProtocol = PostService()
    
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
        let queryItems = [
            URLQueryItem(name: "wall", value: wall.rawValue),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        // Try to decode as PostListResponse with pagination structure
        do {
            return try await networkClient.performRequest(request)
        } catch NetworkError.cancelled {
            // Re-throw cancellation errors without logging
            throw NetworkError.cancelled
        } catch {
            // If backend returns a different structure, try to handle gracefully
            // This can happen if backend hasn't been updated yet
            Logger.data.warning("Failed to decode PostListResponse: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Get a single post by ID
    func getPost(
        postId: String,
        token: String,
        userId: String
    ) async throws -> Post {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Create a new post
    func createPost(title: String, content: String, wall: WallType = .campus, token: String, userId: String) async throws -> Post {
        let body = CreatePostRequest(title: title, content: content, wall: wall.rawValue)
        
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Toggle like on a post
    func toggleLike(postId: String, token: String, userId: String) async throws -> LikeResponse {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/likes")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Hide/delete a post (soft delete)
    func hidePost(postId: String, token: String, userId: String) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/hide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Unhide a post (restore from soft delete)
    func unhidePost(postId: String, token: String, userId: String) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/unhide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Comment Operations
    
    /// Add a comment to a post
    func addComment(postId: String, text: String, token: String, userId: String) async throws -> Comment {
        let body = CreateCommentRequest(text: text)
        
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/comments")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
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
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]
        
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/comments")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Hide/delete a comment (soft delete)
    func hideComment(postId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/comments/\(commentId)/hide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Unhide a comment (restore from soft delete)
    func unhideComment(postId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/comments/\(commentId)/unhide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    // MARK: - Report Operations
    
    /// Report a post
    func reportPost(postId: String, reason: String?, token: String, userId: String) async throws -> ReportResponse {
        let body = ReportRequest(reason: reason)
        
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/reports")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Report a comment
    func reportComment(postId: String, commentId: String, reason: String?, token: String, userId: String) async throws -> ReportResponse {
        let body = ReportRequest(reason: reason)
        
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/comments/\(commentId)/reports")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
}
