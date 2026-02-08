//
//  PostServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for post service operations
//

import Foundation

protocol PostServiceProtocol {
    // MARK: - Post Operations
    
    /// Fetch list of posts
    func fetchPosts(
        token: String,
        userId: String,
        wall: WallType,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> PostListResponse
    
    /// Get a single post by ID
    func getPost(
        postId: String,
        token: String,
        userId: String
    ) async throws -> Post
    
    /// Create a new post
    func createPost(title: String, content: String, wall: WallType, token: String, userId: String) async throws -> Post
    
    /// Toggle like on a post
    func toggleLike(postId: String, token: String, userId: String) async throws -> LikeResponse
    
    /// Hide/delete a post (soft delete)
    func hidePost(postId: String, token: String, userId: String) async throws -> HidePostResponse
    
    // MARK: - Comment Operations
    
    /// Add a comment to a post
    func addComment(postId: String, text: String, token: String, userId: String) async throws -> Comment
    
    /// Get comments for a post
    func getComments(
        postId: String,
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse
    
    /// Hide/delete a comment (soft delete)
    func hideComment(postId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse
    
    // MARK: - User Operations
    
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
}
