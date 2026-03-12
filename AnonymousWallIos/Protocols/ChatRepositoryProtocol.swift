//
//  ChatRepositoryProtocol.swift
//  AnonymousWallIos
//

import Foundation
import UIKit
import Combine

@MainActor
protocol ChatRepositoryProtocol: AnyObject {

    // MARK: - State

    var connectionState: WebSocketConnectionState { get }
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> { get }

    // MARK: - Publishers

    var messagePublisher: AnyPublisher<(Message, String), Never> { get }
    var typingPublisher: AnyPublisher<String, Never> { get }
    var conversationReadPublisher: AnyPublisher<String, Never> { get }
    var readReceiptPublisher: AnyPublisher<String, Never> { get }
    var unreadCountPublisher: AnyPublisher<Int, Never> { get }

    // MARK: - Connection

    func connect(token: String, userId: String)
    func disconnect()
    func disconnectForBackground()
    func updateCachedToken(_ token: String)

    // MARK: - Messages

    func loadMessagesAndConnect(
        otherUserId: String, token: String, userId: String,
        page: Int, limit: Int
    ) async throws -> MessageHistoryResponse

    func loadMessages(
        otherUserId: String, token: String, userId: String,
        page: Int, limit: Int
    ) async throws -> MessageHistoryResponse

    func sendMessage(
        receiverId: String, content: String,
        token: String, userId: String
    ) async throws -> String

    func sendImageMessage(
        image: UIImage, receiverId: String,
        token: String, userId: String
    ) async throws

    func getCachedMessages(for otherUserId: String) async -> [Message]
    func leaveConversation(otherUserId: String)

    // MARK: - Read Status

    func markAsRead(
        messageId: String, otherUserId: String,
        token: String, userId: String
    ) async throws

    func markConversationAsRead(
        otherUserId: String, token: String, userId: String
    ) async throws

    // MARK: - Typing

    func sendTypingIndicator(receiverId: String)

    // MARK: - Conversations

    func loadConversations(token: String, userId: String) async throws -> [Conversation]
}
