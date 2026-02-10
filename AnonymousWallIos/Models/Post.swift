//
//  Post.swift
//  AnonymousWallIos
//
//  Post model for anonymous wall posts
//

import Foundation

struct Post: Codable, Identifiable, Hashable {
    let id: String
    /// Post title (required, 1-255 characters)
    let title: String
    let content: String
    let wall: String
    let likes: Int
    let comments: Int
    let liked: Bool
    let author: Author
    let createdAt: String
    let updatedAt: String
    
    struct Author: Codable, Hashable {
        let id: String
        let profileName: String
        let isAnonymous: Bool
    }
    
    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case wall
        case likes
        case comments
        case liked
        case author
        case createdAt
        case updatedAt
    }
    
    /// Create a copy of this post with updated like status
    func withUpdatedLike(liked: Bool, likes: Int) -> Post {
        return Post(
            id: self.id,
            title: self.title,
            content: self.content,
            wall: self.wall,
            likes: likes,
            comments: self.comments,
            liked: liked,
            author: self.author,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
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
    /// Post title (required, 1-255 characters)
    let title: String
    /// Post content (required, 1-5000 characters)
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
    let likeCount: Int
}

struct HidePostResponse: Codable {
    let message: String
}

struct ReportRequest: Codable {
    let reason: String?
}

struct ReportResponse: Codable {
    let message: String
}
