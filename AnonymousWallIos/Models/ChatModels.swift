//
//  ChatModels.swift
//  AnonymousWallIos
//
//  Chat-related models for messaging functionality
//

import Foundation

// MARK: - Message

/// Represents a chat message between two users
struct Message: Codable, Identifiable, Hashable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let readStatus: Bool
    let createdAt: String
    
    /// Local-only status for UI (not from API)
    var localStatus: MessageStatus = .sent
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case receiverId
        case content
        case readStatus
        case createdAt
    }
    
    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Create a copy with updated read status
    func withReadStatus(_ read: Bool) -> Message {
        var updated = Message(
            id: self.id,
            senderId: self.senderId,
            receiverId: self.receiverId,
            content: self.content,
            readStatus: read,
            createdAt: self.createdAt
        )
        updated.localStatus = read ? .read : .delivered
        return updated
    }
    
    /// Create a copy with updated local status
    func withLocalStatus(_ status: MessageStatus) -> Message {
        var copy = self
        copy.localStatus = status
        return copy
    }
    
    /// Parse ISO8601 timestamp
    var timestamp: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt)
    }
}

// MARK: - Message Status

/// Local message status for optimistic UI updates
enum MessageStatus: String, Codable {
    case sending    // Message is being sent
    case sent       // Message sent to server
    case delivered  // Message delivered to recipient
    case read       // Message read by recipient
    case failed     // Message failed to send
}

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

// MARK: - API Request/Response Models

struct SendMessageRequest: Codable {
    let receiverId: String
    let content: String
}

struct MessageHistoryResponse: Codable {
    let messages: [Message]
    let pagination: MessagePagination
}

struct MessagePagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

struct ConversationsResponse: Codable {
    let conversations: [Conversation]
}

struct MarkReadResponse: Codable {
    let message: String
}

// MARK: - WebSocket Message Types

/// WebSocket message envelope
struct WebSocketMessage: Codable {
    let type: WebSocketMessageType
    let receiverId: String?
    let content: String?
    let messageId: String?
    let message: Message?
    let senderId: String?
    let count: Int?
    let userId: String?
    let timestamp: Int64?
    let error: String?
}

/// WebSocket message types
enum WebSocketMessageType: String, Codable {
    // Client to Server
    case message        // Send message
    case typing         // Typing indicator
    case markRead       // Mark message as read
    
    // Server to Client
    case connected      // Connection established
    case unreadCount    // Unread message count
    case readReceipt    // Read receipt notification
    case error          // Error message
}

// MARK: - WebSocket Connection State

enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed(Error)
}

// MARK: - Temporary Message

/// Temporary message for optimistic UI (before server confirmation)
struct TemporaryMessage {
    let temporaryId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    
    /// Convert to Message once server confirms
    func toMessage(serverId: String, senderId: String) -> Message {
        let formatter = ISO8601DateFormatter()
        return Message(
            id: serverId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            readStatus: false,
            createdAt: formatter.string(from: timestamp)
        )
    }
    
    /// Create a display Message for optimistic UI
    func toDisplayMessage(senderId: String) -> Message {
        let formatter = ISO8601DateFormatter()
        var message = Message(
            id: temporaryId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            readStatus: false,
            createdAt: formatter.string(from: timestamp)
        )
        message.localStatus = .sending
        return message
    }
}
