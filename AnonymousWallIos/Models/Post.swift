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
    let authorId: String
    let createdAt: String
    let likesCount: Int
    let isLikedByCurrentUser: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case createdAt
        case likesCount
        case isLikedByCurrentUser
    }
}

struct PostListResponse: Codable {
    let posts: [Post]
    let total: Int?
}

struct CreatePostRequest: Codable {
    let content: String
}

struct CreatePostResponse: Codable {
    let post: Post
}
