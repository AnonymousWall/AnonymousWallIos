//
//  ChatModels.swift
//  AnonymousWallIos
//
//  Chat-related models for messaging functionality
//

import Foundation

// MARK: - API Request/Response Wrappers

struct SendMessageRequest: Codable {
    let receiverId: String
    let content: String
    let imageUrl: String?

    init(receiverId: String, content: String, imageUrl: String? = nil) {
        self.receiverId = receiverId
        self.content = content
        self.imageUrl = imageUrl
    }
}

struct ConversationsResponse: Codable {
    let conversations: [Conversation]
}

struct MarkReadResponse: Codable {
    let message: String
}

// MARK: - WebSocket

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

enum WebSocketMessageType: String, Codable {
    case message
    case typing
    case markRead
    case connected
    case unreadCount
    case readReceipt
    case error
}

enum WebSocketConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed(Error)

    static func == (lhs: WebSocketConnectionState, rhs: WebSocketConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.reconnecting, .reconnecting),
             (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Temporary Message

struct TemporaryMessage {
    let temporaryId: String
    let receiverId: String
    let content: String
    let timestamp: Date

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
