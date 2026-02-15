//
//  ChatRepository.swift
//  AnonymousWallIos
//
//  Repository layer combining REST API and WebSocket for chat
//

import Foundation
import Combine

/// Repository combining REST and WebSocket for chat functionality
@MainActor
class ChatRepository {
    
    // MARK: - Properties
    
    private let chatService: ChatServiceProtocol
    private let webSocketManager: ChatWebSocketManagerProtocol
    private let messageStore: MessageStore
    
    private var cancellables = Set<AnyCancellable>()
    
    // Subject for conversation read events
    private let conversationReadSubject = PassthroughSubject<String, Never>()
    
    // Track current user ID for determining conversation partner
    private var currentUserId: String?
    
    // Published properties for UI observation
    @Published private(set) var connectionState: WebSocketConnectionState = .disconnected
    
    // Combine publishers
    var messagePublisher: AnyPublisher<(Message, String), Never> {
        webSocketManager.messagePublisher
            .compactMap { [weak self] message -> (Message, String)? in
                guard let self = self, let currentUserId = self.currentUserId else { return nil }
                
                // Determine conversation user ID (the other user in the conversation)
                // If I sent the message: conversation is with the receiver
                // If I received the message: conversation is with the sender
                let conversationUserId: String
                if message.senderId == currentUserId {
                    conversationUserId = message.receiverId
                } else {
                    conversationUserId = message.senderId
                }
                
                return (message, conversationUserId)
            }
            .eraseToAnyPublisher()
    }
    
    var typingPublisher: AnyPublisher<String, Never> {
        webSocketManager.typingPublisher
    }
    
    var readReceiptPublisher: AnyPublisher<String, Never> {
        webSocketManager.readReceiptPublisher
    }
    
    var unreadCountPublisher: AnyPublisher<Int, Never> {
        webSocketManager.unreadCountPublisher
    }
    
    /// Publisher that notifies when a conversation is marked as read (user ID)
    var conversationReadPublisher: AnyPublisher<String, Never> {
        conversationReadSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(
        chatService: ChatServiceProtocol = ChatService.shared,
        webSocketManager: ChatWebSocketManagerProtocol,
        messageStore: MessageStore
    ) {
        self.chatService = chatService
        self.webSocketManager = webSocketManager
        self.messageStore = messageStore
        
        setupWebSocketObservers()
    }
    
    // MARK: - Connection Management
    
    /// Connect to WebSocket
    /// - Parameters:
    ///   - token: Authentication token
    ///   - userId: Current user ID
    func connect(token: String, userId: String) {
        self.currentUserId = userId
        webSocketManager.connect(token: token, userId: userId)
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        webSocketManager.disconnect()
    }
    
    // MARK: - Message Operations
    
    /// Load initial messages via REST API
    /// - Parameters:
    ///   - otherUserId: The other user's ID
    ///   - token: Authentication token
    ///   - userId: Current user ID
    ///   - page: Page number (default: 1)
    ///   - limit: Messages per page (default: 50)
    /// - Returns: Array of messages
    func loadMessages(otherUserId: String, token: String, userId: String, page: Int = 1, limit: Int = 50) async throws -> [Message] {
        let response = try await chatService.getMessageHistory(
            otherUserId: otherUserId,
            page: page,
            limit: limit,
            token: token,
            userId: userId
        )
        
        // Store messages
        await messageStore.addMessages(response.messages, for: otherUserId)
        
        return response.messages
    }
    
    /// Send message with optimistic UI update
    /// - Parameters:
    ///   - receiverId: Recipient user ID
    ///   - content: Message content
    ///   - token: Authentication token
    ///   - userId: Current user ID
    /// - Returns: Temporary message ID for tracking
    func sendMessage(receiverId: String, content: String, token: String, userId: String) async throws -> String {
        // Create temporary message for optimistic UI
        let temporaryId = UUID().uuidString
        let tempMessage = TemporaryMessage(
            temporaryId: temporaryId,
            receiverId: receiverId,
            content: content,
            timestamp: Date()
        )
        
        // Store temporary message
        await messageStore.addTemporaryMessage(tempMessage)
        
        // Add to conversation for immediate UI update
        let displayMessage = tempMessage.toDisplayMessage(senderId: userId)
        await messageStore.addMessage(displayMessage, for: receiverId)
        
        // Send via WebSocket if connected, otherwise fallback to REST
        if case .connected = webSocketManager.connectionState {
            webSocketManager.sendMessage(receiverId: receiverId, content: content)
        } else {
            // Fallback to REST API
            Task {
                do {
                    let confirmedMessage = try await chatService.sendMessage(
                        receiverId: receiverId,
                        content: content,
                        token: token,
                        userId: userId
                    )
                    
                    // Replace temporary message with confirmed one
                    await messageStore.confirmTemporaryMessage(
                        temporaryId: temporaryId,
                        confirmedMessage: confirmedMessage,
                        for: receiverId
                    )
                    
                    // Update status to sent
                    await messageStore.updateLocalStatus(
                        messageId: confirmedMessage.id,
                        for: receiverId,
                        status: .sent
                    )
                } catch {
                    // Mark as failed
                    await messageStore.updateLocalStatus(
                        messageId: temporaryId,
                        for: receiverId,
                        status: .failed
                    )
                    throw error
                }
            }
        }
        
        return temporaryId
    }
    
    /// Get cached messages for a conversation
    /// - Parameter otherUserId: The other user's ID
    /// - Returns: Cached messages
    func getCachedMessages(for otherUserId: String) async -> [Message] {
        return await messageStore.getMessages(for: otherUserId)
    }
    
    /// Mark message as read
    /// - Parameters:
    ///   - messageId: Message ID
    ///   - otherUserId: The other user's ID
    ///   - token: Authentication token
    ///   - userId: Current user ID
    func markAsRead(messageId: String, otherUserId: String, token: String, userId: String) async throws {
        // Update locally first
        await messageStore.updateReadStatus(messageId: messageId, for: otherUserId, read: true)
        
        // Send via WebSocket if connected
        if case .connected = webSocketManager.connectionState {
            webSocketManager.markAsRead(messageId: messageId)
        }
        
        // Also send via REST for reliability
        try await chatService.markMessageAsRead(messageId: messageId, token: token, userId: userId)
    }
    
    /// Mark conversation as read
    /// - Parameters:
    ///   - otherUserId: The other user's ID
    ///   - token: Authentication token
    ///   - userId: Current user ID
    func markConversationAsRead(otherUserId: String, token: String, userId: String) async throws {
        // Update locally first
        await messageStore.markAllAsRead(for: otherUserId)
        
        // Send to server
        try await chatService.markConversationAsRead(otherUserId: otherUserId, token: token, userId: userId)
        
        // Notify observers that this conversation was marked as read
        conversationReadSubject.send(otherUserId)
    }
    
    /// Send typing indicator
    /// - Parameter receiverId: Recipient user ID
    func sendTypingIndicator(receiverId: String) {
        guard case .connected = webSocketManager.connectionState else { return }
        webSocketManager.sendTypingIndicator(receiverId: receiverId)
    }
    
    /// Send read receipt via WebSocket
    /// - Parameter messageId: Message ID to mark as read
    func sendReadReceipt(messageId: String) {
        guard case .connected = webSocketManager.connectionState else { return }
        webSocketManager.markAsRead(messageId: messageId)
    }
    
    /// Load conversations list
    /// - Parameters:
    ///   - token: Authentication token
    ///   - userId: Current user ID
    /// - Returns: Array of conversations
    func loadConversations(token: String, userId: String) async throws -> [Conversation] {
        return try await chatService.getConversations(token: token, userId: userId)
    }
    
    /// Recover messages (fallback when WebSocket disconnects)
    /// - Parameters:
    ///   - otherUserId: The other user's ID
    ///   - token: Authentication token
    ///   - userId: Current user ID
    /// - Returns: New messages received while disconnected
    func recoverMessages(otherUserId: String, token: String, userId: String) async throws -> [Message] {
        // Get last known message timestamp
        guard let lastMessage = await messageStore.getLastMessage(for: otherUserId),
              let lastTimestamp = lastMessage.timestamp else {
            // No messages yet, load initial batch
            return try await loadMessages(otherUserId: otherUserId, token: token, userId: userId)
        }
        
        // Fetch newer messages
        let response = try await chatService.getMessageHistory(
            otherUserId: otherUserId,
            page: 1,
            limit: 100,
            token: token,
            userId: userId
        )
        
        // Filter to only newer messages
        let newerMessages = response.messages.filter { message in
            guard let messageTimestamp = message.timestamp else { return false }
            return messageTimestamp > lastTimestamp
        }
        
        // Store new messages
        await messageStore.addMessages(newerMessages, for: otherUserId)
        
        return newerMessages
    }
    
    // MARK: - Private Methods
    
    private func setupWebSocketObservers() {
        // Observe connection state
        webSocketManager.connectionStatePublisher
            .sink { [weak self] state in
                self?.connectionState = state
                
                // Handle reconnection - recover messages
                if case .connected = state {
                    Logger.chat.info("WebSocket reconnected, recovering messages")
                }
            }
            .store(in: &cancellables)
        
        // Observe incoming messages and store them
        webSocketManager.messagePublisher
            .sink { [weak self] message in
                guard let self = self, let currentUserId = self.currentUserId else { return }
                
                Task {
                    // Determine conversation user ID (the other user in the conversation)
                    // If I sent the message: conversation is with the receiver
                    // If I received the message: conversation is with the sender
                    let conversationUserId: String
                    if message.senderId == currentUserId {
                        conversationUserId = message.receiverId
                        Logger.chat.info("WebSocket message from me to \(conversationUserId), storing in conversation with \(conversationUserId)")
                    } else {
                        conversationUserId = message.senderId
                        Logger.chat.info("WebSocket message from \(conversationUserId) to me, storing in conversation with \(conversationUserId)")
                    }
                    
                    await self.messageStore.addMessage(message, for: conversationUserId)
                }
            }
            .store(in: &cancellables)
        
        // Observe read receipts
        webSocketManager.readReceiptPublisher
            .sink { [weak self] messageId in
                guard let self = self else { return }
                
                Task {
                    // Update read status for the message
                    // Note: We need to find which conversation this message belongs to
                    // This is a simplification - in production you'd track message-to-conversation mapping
                    Logger.chat.info("Received read receipt for message: \(messageId)")
                }
            }
            .store(in: &cancellables)
    }
}
