//
//  Conversation.swift
//  AnonymousWallIos
//
//  Created by Ziyi Huang on 3/11/26.
//

import Foundation

// MARK: - Conversation

/// Represents a conversation with another user
struct Conversation: Codable, Identifiable {
    let userId: String
    let profileName: String
    let lastMessage: Message?
    let unreadCount: Int
    
    // Identifiable conformance
    var id: String { userId }
}
