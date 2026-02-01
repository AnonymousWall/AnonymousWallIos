//
//  Post.swift
//  AnonymousWallIos
//
//  Post model for anonymous wall posts
//

import Foundation

struct Post: Codable, Identifiable {
    let id: String
    let content: String
    let wall: String
    let likes: Int
    let comments: Int
    let liked: Bool
    let author: Author
    let createdAt: String
    let updatedAt: String
    
    struct Author: Codable {
        let id: String
        let isAnonymous: Bool
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case wall
        case likes
        case comments
        case liked
        case author
        case createdAt
        case updatedAt
    }
}

struct PostListResponse: Codable {
    let data: [Post]
    let pagination: Pagination
    
    struct Pagination: Codable {
        let page: Int
        let limit: Int
        let total: Int
        let totalPages: Int
    }
}

struct CreatePostRequest: Codable {
    let content: String
    let wall: String
}

struct CreatePostResponse: Codable {
    let post: Post
}

struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let text: String
    let author: Post.Author
    let createdAt: String
}

struct CommentListResponse: Codable {
    let data: [Comment]
    let pagination: PostListResponse.Pagination
}

struct CreateCommentRequest: Codable {
    let text: String
}

struct LikeResponse: Codable {
    let liked: Bool
}

struct HidePostResponse: Codable {
    let message: String
}
