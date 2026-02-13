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
