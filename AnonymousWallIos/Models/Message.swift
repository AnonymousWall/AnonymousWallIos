//
//  Message.swift
//  AnonymousWallIos
//
//  Created by Ziyi Huang on 3/11/26.
//

import Foundation

// MARK: - Message

/// Represents a chat message between two users
struct Message: Codable, Identifiable, Hashable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let imageUrl: String?
    let readStatus: Bool
    let createdAt: String
    
    /// Local-only status for UI (not from API)
    var localStatus: MessageStatus = .sent
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case receiverId
        case content
        case imageUrl
        case readStatus
        case createdAt
    }
    
    // Custom decoder to set localStatus based on readStatus
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        senderId = try container.decode(String.self, forKey: .senderId)
        receiverId = try container.decode(String.self, forKey: .receiverId)
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        readStatus = try container.decode(Bool.self, forKey: .readStatus)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        
        // Set localStatus based on readStatus from server
        localStatus = readStatus ? .read : .sent
    }
    
    // Manual init for creating messages programmatically
    init(id: String, senderId: String, receiverId: String, content: String, imageUrl: String? = nil, readStatus: Bool, createdAt: String) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.imageUrl = imageUrl
        self.readStatus = readStatus
        self.createdAt = createdAt
        self.localStatus = readStatus ? .read : .sent
    }
    
    // Hashable conformance based on id
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Include localStatus in equality check so SwiftUI detects changes
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.readStatus == rhs.readStatus &&
        lhs.localStatus == rhs.localStatus
    }
    
    /// Create a copy with updated read status
    func withReadStatus(_ read: Bool) -> Message {
        var updated = Message(
            id: self.id,
            senderId: self.senderId,
            receiverId: self.receiverId,
            content: self.content,
            imageUrl: self.imageUrl,
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
    private static let iso8601Formatter = ISO8601DateFormatter()
    var timestamp: Date? {
        Message.iso8601Formatter.date(from: createdAt)
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
