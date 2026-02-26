//
//  PostEnums.swift
//  AnonymousWallIos
//
//  Enums for post-related constants
//

import Foundation

/// Wall type for posts
enum WallType: String, Codable, CaseIterable {
    case campus = "campus"
    case national = "national"
    
    var displayName: String {
        switch self {
        case .campus:
            return "Campus"
        case .national:
            return "National"
        }
    }
}

/// Sort order for posts and comments
enum SortOrder: String, Codable, CaseIterable {
    case newest = "NEWEST"
    case oldest = "OLDEST"
    case mostLiked = "MOST_LIKED"
    case leastLiked = "LEAST_LIKED"
    case mostCommented = "MOST_COMMENTED"
    case leastCommented = "LEAST_COMMENTED"
    
    var displayName: String {
        switch self {
        case .newest:
            return "Recent"
        case .oldest:
            return "Oldest"
        case .mostLiked:
            return "Most Likes"
        case .leastLiked:
            return "Least Likes"
        case .mostCommented:
            return "Most Comments"
        case .leastCommented:
            return "Least Comments"
        }
    }
    
    /// Sorting options suitable for the main feed segmented control
    static var feedOptions: [SortOrder] {
        return [.newest, .mostLiked, .mostCommented, .oldest]
    }
}

/// Sort order for marketplace items
enum MarketplaceSortOrder: String, CaseIterable {
    case newest = "newest"
    case priceAsc = "price-asc"
    case priceDesc = "price-desc"
    
    var displayName: String {
        switch self {
        case .newest: return "Newest"
        case .priceAsc: return "Price ↑"
        case .priceDesc: return "Price ↓"
        }
    }
}

/// Category for marketplace items
enum MarketplaceCategory: String, CaseIterable, Codable {
    case textbooks   = "textbooks"
    case electronics = "electronics"
    case furniture   = "furniture"
    case clothing    = "clothing"
    case stationery  = "stationery"
    case sports      = "sports"
    case transport   = "transport"
    case food        = "food"
    case services    = "services"
    case housing     = "housing"
    case tickets     = "tickets"
    case other       = "other"

    var displayName: String {
        switch self {
        case .textbooks:   return "Textbooks"
        case .electronics: return "Electronics"
        case .furniture:   return "Furniture"
        case .clothing:    return "Clothing"
        case .stationery:  return "Stationery"
        case .sports:      return "Sports & Fitness"
        case .transport:   return "Transport"
        case .food:        return "Food & Drinks"
        case .services:    return "Services"
        case .housing:     return "Housing"
        case .tickets:     return "Tickets"
        case .other:       return "Other"
        }
    }

    var icon: String {
        switch self {
        case .textbooks:   return "books.vertical"
        case .electronics: return "laptopcomputer"
        case .furniture:   return "sofa"
        case .clothing:    return "tshirt"
        case .stationery:  return "pencil.and.ruler"
        case .sports:      return "figure.run"
        case .transport:   return "bicycle"
        case .food:        return "cup.and.saucer"
        case .services:    return "wrench.and.screwdriver"
        case .housing:     return "house"
        case .tickets:     return "ticket"
        case .other:       return "square.grid.2x2"
        }
    }
}
