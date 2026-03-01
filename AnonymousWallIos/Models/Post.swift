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
    let imageUrls: [String]
    let author: Author
    let createdAt: String
    let updatedAt: String
    /// "standard" or "poll"; nil decoded as "standard"
    let postType: String?
    /// Total poll votes; nil for standard posts
    let totalVotes: Int?
    /// Poll data; nil for standard posts
    var poll: PollDTO?
    
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
        case id, title, content, wall, likes, comments, liked, author, createdAt, updatedAt
        case imageUrls, postType, totalVotes, poll
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        wall = try container.decode(String.self, forKey: .wall)
        likes = try container.decode(Int.self, forKey: .likes)
        comments = try container.decode(Int.self, forKey: .comments)
        liked = try container.decode(Bool.self, forKey: .liked)
        imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        author = try container.decode(Author.self, forKey: .author)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        postType = try container.decodeIfPresent(String.self, forKey: .postType)
        totalVotes = try container.decodeIfPresent(Int.self, forKey: .totalVotes)
        poll = try container.decodeIfPresent(PollDTO.self, forKey: .poll)
    }
    
    init(
        id: String,
        title: String,
        content: String,
        wall: String,
        likes: Int,
        comments: Int,
        liked: Bool,
        imageUrls: [String] = [],
        author: Author,
        createdAt: String,
        updatedAt: String,
        postType: String? = nil,
        totalVotes: Int? = nil,
        poll: PollDTO? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.wall = wall
        self.likes = likes
        self.comments = comments
        self.liked = liked
        self.imageUrls = imageUrls
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.postType = postType
        self.totalVotes = totalVotes
        self.poll = poll
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
            imageUrls: self.imageUrls,
            author: self.author,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            postType: self.postType,
            totalVotes: self.totalVotes,
            poll: self.poll
        )
    }
    
    /// Create a copy of this post with updated comment count
    func withUpdatedComments(comments: Int) -> Post {
        return Post(
            id: self.id,
            title: self.title,
            content: self.content,
            wall: self.wall,
            likes: self.likes,
            comments: comments,
            liked: self.liked,
            imageUrls: self.imageUrls,
            author: self.author,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            postType: self.postType,
            totalVotes: self.totalVotes,
            poll: self.poll
        )
    }
    
    /// Create a copy of this post with updated poll data
    func withUpdatedPoll(_ poll: PollDTO) -> Post {
        return Post(
            id: self.id,
            title: self.title,
            content: self.content,
            wall: self.wall,
            likes: self.likes,
            comments: self.comments,
            liked: self.liked,
            imageUrls: self.imageUrls,
            author: self.author,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            postType: self.postType,
            totalVotes: poll.totalVotes,
            poll: poll
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
    /// Post content (optional for poll posts)
    let content: String?
    let wall: String
    /// "poll" or "standard"; nil defaults to standard
    let postType: String?
    /// 2–4 option strings; required when postType == "poll"
    let pollOptions: [String]?
}

struct CreatePostResponse: Codable {
    let post: Post
}

struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    /// Parent entity type: "POST", "INTERNSHIP", or "MARKETPLACE"
    let parentType: String?
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
