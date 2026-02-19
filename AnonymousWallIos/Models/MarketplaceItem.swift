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
    let sold: Bool
    let wall: String
    let comments: Int
    let author: Post.Author
    let createdAt: String
    let updatedAt: String

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
            sold: self.sold,
            wall: self.wall,
            comments: comments,
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
    let sold: Bool?
}
