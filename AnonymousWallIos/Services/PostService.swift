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

    func getPost(postId: String, token: String, userId: String) async throws -> Post {
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId)")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Create a new post (single multipart request, supports up to 5 images)
        func createPost(
            title: String,
            content: String,
            wall: WallType = .campus,
            images: [UIImage] = [],
            token: String,
            userId: String
        ) async throws -> Post {
            guard let url = URL(string: config.fullAPIBaseURL + "/posts") else {
                throw NetworkError.invalidURL
            }

            let boundary = UUID().uuidString
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue(userId, forHTTPHeaderField: "X-User-Id")
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.timeoutInterval = 60
            urlRequest.assumesHTTP3Capable = false

            var body = Data()
            body.appendFormField(name: "title", value: title, boundary: boundary)
            body.appendFormField(name: "content", value: content, boundary: boundary)
            body.appendFormField(name: "wall", value: wall.rawValue, boundary: boundary)

            for (index, image) in images.prefix(5).enumerated() {
                let resized = image.resized(maxDimension: 1024)
                if let jpeg = resized.jpegData(compressionQuality: 0.6) {
                    body.appendFileField(
                        name: "images",
                        filename: "image\(index).jpg",
                        mimeType: "image/jpeg",
                        data: jpeg,
                        boundary: boundary
                    )
                }
            }

            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            urlRequest.httpBody = body

            let sessionConfig = URLSessionConfiguration.ephemeral
            sessionConfig.waitsForConnectivity = true
            let session = URLSession(configuration: sessionConfig)

            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError("Invalid response")
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 { throw NetworkError.unauthorized }
                if httpResponse.statusCode == 403 { throw NetworkError.forbidden }
                let message = String(data: data, encoding: .utf8) ?? "Server error"
                throw NetworkError.serverError(message)
            }

            return try JSONDecoder().decode(Post.self, from: data)
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
    
    // MARK: - Poll Operations
    
    /// Create a poll post (JSON request — no image upload for poll posts)
    func createPollPost(
        title: String,
        content: String?,
        wall: WallType,
        pollOptions: [String],
        token: String,
        userId: String
    ) async throws -> Post {
        let body = CreatePostRequest(
            title: title,
            content: content,
            wall: wall.rawValue,
            postType: "poll",
            pollOptions: pollOptions
        )
        
        let request = try APIRequestBuilder()
            .setPath("/posts")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Vote on a poll option
    func votePoll(postId: UUID, optionId: UUID, token: String, userId: String) async throws -> PollDTO {
        let body = PollVoteRequest(optionId: optionId)
        
        let request = try APIRequestBuilder()
            .setPath("/posts/\(postId.uuidString)/vote")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()
        
        return try await networkClient.performRequest(request)
    }
    
    /// Fetch poll details
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
