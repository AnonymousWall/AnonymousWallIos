//
//  CommentParent.swift
//  AnonymousWallIos
//
//  Wrapper for different parent types of comments
//

import Foundation

enum CommentParent: Hashable {
    case post(Post)
    case internship(Internship)
    case marketplace(MarketplaceItem)
    
    var id: String {
        switch self {
        case .post(let post): 
            return post.id
        case .internship(let internship): 
            return internship.id
        case .marketplace(let item): 
            return item.id
        }
    }
    
    var parentType: String {
        switch self {
        case .post: return "POST"
        case .internship: return "INTERNSHIP"
        case .marketplace: return "MARKETPLACE"
        }
    }
}
