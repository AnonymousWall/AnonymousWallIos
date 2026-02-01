//
//  PostService.swift
//  AnonymousWallIos
//
//  Service for post-related API calls
//

import Foundation

class PostService {
    static let shared = PostService()
    
    private let baseURL = "http://localhost:8080"
    
    private init() {}
    
    // MARK: - Post Operations
    
    /// Fetch list of posts
    func fetchPosts(token: String, userId: String, page: Int = 1, limit: Int = 20) async throws -> [Post] {
        guard let url = URL(string: "\(baseURL)/api/v1/posts?page=\(page)&limit=\(limit)") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            // Try to decode as PostListResponse first, fall back to array
            if let listResponse = try? JSONDecoder().decode(PostListResponse.self, from: data) {
                return listResponse.posts
            } else if let posts = try? JSONDecoder().decode([Post].self, from: data) {
                return posts
            } else {
                throw AuthError.decodingError
            }
        } else if httpResponse.statusCode == 401 {
            throw AuthError.unauthorized
        } else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
               let errorMessage = errorResponse.error ?? errorResponse.message {
                throw AuthError.serverError(errorMessage)
            }
            throw AuthError.serverError("Failed to fetch posts")
        }
    }
    
    /// Create a new post
    func createPost(content: String, token: String, userId: String) async throws -> Post {
        guard let url = URL(string: "\(baseURL)/api/v1/posts") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let body = CreatePostRequest(content: content)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            // Try to decode as CreatePostResponse first, fall back to Post
            if let createResponse = try? JSONDecoder().decode(CreatePostResponse.self, from: data) {
                return createResponse.post
            } else if let post = try? JSONDecoder().decode(Post.self, from: data) {
                return post
            } else {
                throw AuthError.decodingError
            }
        } else if httpResponse.statusCode == 401 {
            throw AuthError.unauthorized
        } else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
               let errorMessage = errorResponse.error ?? errorResponse.message {
                throw AuthError.serverError(errorMessage)
            }
            throw AuthError.serverError("Failed to create post")
        }
    }
    
    /// Delete a post
    func deletePost(postId: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/posts/\(postId)") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.statusCode == 401 {
                throw AuthError.unauthorized
            }
            throw AuthError.serverError("Failed to delete post")
        }
    }
    
    /// Like a post
    func likePost(postId: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/posts/\(postId)/like") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.statusCode == 401 {
                throw AuthError.unauthorized
            }
            throw AuthError.serverError("Failed to like post")
        }
    }
    
    /// Unlike a post
    func unlikePost(postId: String, token: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/posts/\(postId)/like") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.statusCode == 401 {
                throw AuthError.unauthorized
            }
            throw AuthError.serverError("Failed to unlike post")
        }
    }
}
