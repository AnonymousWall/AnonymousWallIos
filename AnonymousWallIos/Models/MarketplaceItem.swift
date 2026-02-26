//
//  MarketplaceItem.swift
//  AnonymousWallIos
//
//  Model for marketplace items
//

import Foundation

struct MarketplaceItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let price: Double
    let description: String?
    let category: String?
    let condition: String?
    let wall: String
    let comments: Int
    let imageUrls: [String]
    let author: Post.Author
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, price, description, category, condition, wall, comments, author, createdAt, updatedAt
        case imageUrls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        price = try container.decode(Double.self, forKey: .price)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        condition = try container.decodeIfPresent(String.self, forKey: .condition)
        wall = try container.decode(String.self, forKey: .wall)
        comments = try container.decode(Int.self, forKey: .comments)
        imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        author = try container.decode(Post.Author.self, forKey: .author)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }

    init(
        id: String,
        title: String,
        price: Double,
        description: String?,
        category: String?,
        condition: String?,
        wall: String,
        comments: Int,
        imageUrls: [String] = [],
        author: Post.Author,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.description = description
        self.category = category
        self.condition = condition
        self.wall = wall
        self.comments = comments
        self.imageUrls = imageUrls
        self.author = author
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MarketplaceItem, rhs: MarketplaceItem) -> Bool {
        lhs.id == rhs.id
    }

    /// Create a copy with updated comment count
    func withUpdatedComments(comments: Int) -> MarketplaceItem {
        return MarketplaceItem(
            id: self.id,
            title: self.title,
            price: self.price,
            description: self.description,
            category: self.category,
            condition: self.condition,
            wall: self.wall,
            comments: comments,
            imageUrls: self.imageUrls,
            author: self.author,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }

    /// Formatted price string
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
}

struct MarketplaceListResponse: Codable {
    let data: [MarketplaceItem]
    let pagination: PostListResponse.Pagination
}

struct CreateMarketplaceRequest: Codable {
    let title: String
    let price: Double
    let description: String?
    let category: String?
    let condition: String?
    let wall: String
}

struct UpdateMarketplaceRequest: Codable {
    let title: String?
    let price: Double?
    let description: String?
    let category: String?
    let condition: String?
}
