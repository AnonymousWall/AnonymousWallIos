//
//  PostService.swift
//  AnonymousWallIos
//
//  Service for post-related API calls
//

import Foundation
import UIKit

class PostService: PostServiceProtocol {
    static let shared: PostServiceProtocol = PostService()
    
    private let config = AppConfiguration.shared
    private let networkClient = NetworkClient.shared
    private let mediaService: MediaServiceProtocol
    
    private init(mediaService: MediaServiceProtocol = MediaService.shared) {
        self.mediaService = mediaService
    }
    
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
        
        do {
            return try await networkClient.performRequest(request)
        } catch NetworkError.cancelled {
            throw NetworkError.cancelled
        } catch {
            Logger.data.warning("Failed to decode PostListResponse: \(error.localizedDescription)")
            throw error
        }
    }

    func getPost(postId: String, token: String, userId: String) async throws -> Post {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    func createPost(
        title: String,
        content: String,
        wall: WallType = .campus,
        images: [UIImage] = [],
        token: String,
        userId: String
    ) async throws -> Post {
        let objectNames = try await mediaService.uploadImages(images, folder: "posts", token: token)

        struct CreatePostBody: Encodable {
            let title: String
            let content: String
            let wall: String
            let imageObjectNames: [String]
        }

        let body = CreatePostBody(
            title: title,
            content: content,
            wall: wall.rawValue,
            imageObjectNames: objectNames
        )

        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .setBody(body)
            .build()

        return try await networkClient.performRequest(request)
    }

    func toggleLike(postId: String, token: String, userId: String) async throws -> LikeResponse {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/likes")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    func hidePost(postId: String, token: String, userId: String) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/hide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
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
    
    func hideComment(postId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)/comments/\(commentId)/hide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
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
    
    // MARK: - Poll Operations
    
    func createPollPost(
        title: String,
        content: String?,
        wall: WallType,
        pollOptions: [String],
        token: String,
        userId: String
    ) async throws -> Post {
        struct CreatePollBody: Encodable {
            let title: String
            let content: String
            let wall: String
            let postType: String
            let pollOptions: [String]
        }

        let body = CreatePollBody(
            title: title,
            content: content ?? "",
            wall: wall.rawValue,
            postType: "poll",
            pollOptions: pollOptions
        )

        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .setBody(body)
            .build()

        return try await networkClient.performRequest(request)
    }
    
    func votePoll(postId: UUID, optionId: UUID, token: String, userId: String) async throws -> PollDTO {
        let body = PollVoteRequest(optionId: optionId)
        
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId.uuidString)/vote")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        let response: VoteResponse = try await networkClient.performRequest(request)
        return response.poll
    }
    
    func getPoll(postId: UUID, viewResults: Bool, token: String, userId: String) async throws -> PollDTO {
        let queryItems = [URLQueryItem(name: "viewResults", value: viewResults ? "true" : "false")]
        
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId.uuidString)/poll")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
}

// MARK: - Private response wrappers

private struct VoteResponse: Codable {
    let poll: PollDTO
    let message: String
}
