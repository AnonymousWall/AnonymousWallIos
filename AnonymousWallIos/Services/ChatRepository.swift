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
    
    // Track pending temporary messages for reconciliation
    private var pendingTemporaryMessages: [String: String] = [:] // [tempId: receiverId]
    
    // Published properties for UI observation
    @Published private(set) var connectionState: WebSocketConnectionState = .disconnected
    
    // Combine publishers
    var messagePublisher: AnyPublisher<(Message, String), Never> {
        webSocketManager.messagePublisher
            .compactMap { [weak self] message -> (Message, String)? in
                guard let self = self else { return nil }
                // Determine conversation user ID (the other user)
                let conversationUserId = message.senderId
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
        
        // Track for reconciliation
        pendingTemporaryMessages[temporaryId] = receiverId
        
        // Add to conversation for immediate UI update
        let displayMessage = tempMessage.toDisplayMessage(senderId: userId)
        await messageStore.addMessage(displayMessage, for: receiverId)
        
        // Send via WebSocket if connected, otherwise fallback to REST
        if case .connected = webSocketManager.connectionState {
            // Send via WebSocket - will be echoed back by server
            webSocketManager.sendMessage(receiverId: receiverId, content: content)
            
            // Also use REST as fallback to ensure delivery
            Task {
                do {
                    let confirmedMessage = try await chatService.sendMessage(
                        receiverId: receiverId,
                        content: content,
                        token: token,
                        userId: userId
                    )
                    
                    // Only reconcile if temp message still pending
                    if pendingTemporaryMessages[temporaryId] != nil {
                        await reconcileTemporaryMessage(
                            temporaryId: temporaryId,
                            confirmedMessage: confirmedMessage,
                            receiverId: receiverId
                        )
                    }
                } catch {
                    // Mark as failed only if still pending
                    if pendingTemporaryMessages[temporaryId] != nil {
                        await messageStore.updateLocalStatus(
                            messageId: temporaryId,
                            for: receiverId,
                            status: .failed
                        )
                        pendingTemporaryMessages.removeValue(forKey: temporaryId)
                    }
                }
            }
        } else {
            // Fallback to REST API only
            Task {
                do {
                    let confirmedMessage = try await chatService.sendMessage(
                        receiverId: receiverId,
                        content: content,
                        token: token,
                        userId: userId
                    )
                    
                    await reconcileTemporaryMessage(
                        temporaryId: temporaryId,
                        confirmedMessage: confirmedMessage,
                        receiverId: receiverId
                    )
                } catch {
                    // Mark as failed
                    await messageStore.updateLocalStatus(
                        messageId: temporaryId,
                        for: receiverId,
                        status: .failed
                    )
                    pendingTemporaryMessages.removeValue(forKey: temporaryId)
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
    }
    
    /// Send typing indicator
    /// - Parameter receiverId: Recipient user ID
    func sendTypingIndicator(receiverId: String) {
        guard case .connected = webSocketManager.connectionState else { return }
        webSocketManager.sendTypingIndicator(receiverId: receiverId)
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
    
    /// Reconcile temporary message with server-confirmed message
    private func reconcileTemporaryMessage(temporaryId: String, confirmedMessage: Message, receiverId: String) async {
        // Remove from pending tracking
        pendingTemporaryMessages.removeValue(forKey: temporaryId)
        
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
    }
    
    /// Reconcile incoming WebSocket message with potential temporary message
    /// Returns true if message was a reconciliation of a temp message, false if it's a new message
    private func reconcileIncomingMessage(_ message: Message, conversationUserId: String) async -> Bool {
        // Check if this is our own sent message (echoed back)
        // Look for pending temporary messages that match
        for (tempId, receiverId) in pendingTemporaryMessages where receiverId == conversationUserId {
            if let tempMsg = await messageStore.getTemporaryMessage(id: tempId),
               tempMsg.content == message.content {
                // This is our sent message echoed back - reconcile it
                await reconcileTemporaryMessage(
                    temporaryId: tempId,
                    confirmedMessage: message,
                    receiverId: receiverId
                )
                return true
            }
        }
        return false
    }
    
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
                guard let self = self else { return }
                
                Task { @MainActor in
                    // Determine conversation user ID (sender for received messages)
                    let conversationUserId = message.senderId
                    
                    // Check if this is a reconciliation of our sent message
                    let isReconciled = await self.reconcileIncomingMessage(message, conversationUserId: conversationUserId)
                    
                    // Only add if not reconciled (to avoid duplicates)
                    if !isReconciled {
                        await self.messageStore.addMessage(message, for: conversationUserId)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe read receipts
        webSocketManager.readReceiptPublisher
            .sink { [weak self] messageId in
                guard let self = self else { return }
                
                Task { @MainActor in
                    // Find the conversation that contains this message and update read status
                    // We need to search all conversations to find the message
                    await self.updateReadReceiptForMessage(messageId: messageId)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Update read receipt for a message across all conversations
    private func updateReadReceiptForMessage(messageId: String) async {
        // Find which conversation contains this message
        if let conversationUserId = await messageStore.findConversation(forMessageId: messageId) {
            await messageStore.updateReadStatus(messageId: messageId, for: conversationUserId, read: true)
            Logger.chat.info("Updated read receipt for message: \(messageId) in conversation: \(conversationUserId)")
        } else {
            Logger.chat.warning("Could not find conversation for message: \(messageId)")
        }
    }
}
