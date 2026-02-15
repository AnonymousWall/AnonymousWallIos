//
//  ChatServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for chat service operations
//

import Foundation

/// Protocol defining chat service operations
protocol ChatServiceProtocol {
    /// Send a message to another user
    /// - Parameters:
    ///   - receiverId: Recipient user ID
    ///   - content: Message content
    ///   - token: Authentication token
    ///   - userId: Current user ID
    /// - Returns: Created message
    func sendMessage(receiverId: String, content: String, token: String, userId: String) async throws -> Message
    
    /// Get message history with another user
    /// - Parameters:
    ///   - otherUserId: The other user's ID
    ///   - page: Page number (default: 1)
    ///   - limit: Messages per page (default: 50, max: 100)
    ///   - token: Authentication token
    ///   - userId: Current user ID
    /// - Returns: Message history response with pagination
    func getMessageHistory(otherUserId: String, page: Int, limit: Int, token: String, userId: String) async throws -> MessageHistoryResponse
    
    /// Get list of conversations
    /// - Parameters:
    ///   - token: Authentication token
    ///   - userId: Current user ID
    /// - Returns: List of conversations
    func getConversations(token: String, userId: String) async throws -> [Conversation]
    
    /// Mark a message as read
    /// - Parameters:
    ///   - messageId: Message ID to mark as read
    ///   - token: Authentication token
    ///   - userId: Current user ID
    func markMessageAsRead(messageId: String, token: String, userId: String) async throws
    
    /// Mark all messages in a conversation as read
    /// - Parameters:
    ///   - otherUserId: The other user's ID
    ///   - token: Authentication token
    ///   - userId: Current user ID
    func markConversationAsRead(otherUserId: String, token: String, userId: String) async throws
}
