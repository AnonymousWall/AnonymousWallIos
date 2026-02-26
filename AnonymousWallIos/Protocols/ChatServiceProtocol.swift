//
//  ChatServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for chat service operations
//

import Foundation
import UIKit

/// Protocol defining chat service operations
protocol ChatServiceProtocol {
    /// Send a text message to another user
    func sendMessage(receiverId: String, content: String, token: String, userId: String) async throws -> Message
    
    /// Send an image message (with pre-uploaded imageUrl)
    func sendImageMessage(receiverId: String, imageUrl: String, token: String, userId: String) async throws -> Message
    
    /// Upload a chat image and return the URL
    func uploadChatImage(_ jpeg: Data, token: String, userId: String) async throws -> String
    
    /// Get message history with another user
    func getMessageHistory(otherUserId: String, page: Int, limit: Int, token: String, userId: String) async throws -> MessageHistoryResponse
    
    /// Get list of conversations
    func getConversations(token: String, userId: String) async throws -> [Conversation]
    
    /// Mark a message as read
    func markMessageAsRead(messageId: String, token: String, userId: String) async throws
    
    /// Mark all messages in a conversation as read
    func markConversationAsRead(otherUserId: String, token: String, userId: String) async throws
}
