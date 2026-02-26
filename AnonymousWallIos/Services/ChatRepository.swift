//
//  ChatRepository.swift
//  AnonymousWallIos
//
//  Repository layer combining REST API and WebSocket for chat
//

import Foundation
import UIKit
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
    
    // Track active conversations that need recovery on reconnect
    private var activeConversations: Set<String> = []
    
    // Store auth credentials for recovery
    private var cachedToken: String?
    private var cachedUserId: String?
    
    // Subject for read status updates
    private var conversationReadSubject = PassthroughSubject<String, Never>()
    private var readReceiptSubject = PassthroughSubject<String, Never>()
    
    // Subject for message updates (emitted AFTER reconciliation)
    private var messageSubject = PassthroughSubject<(Message, String), Never>()
    
    // Published properties for UI observation
    @Published private(set) var connectionState: WebSocketConnectionState = .disconnected
    
    // Combine publishers
    var messagePublisher: AnyPublisher<(Message, String), Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var typingPublisher: AnyPublisher<String, Never> {
        webSocketManager.typingPublisher
    }
    
    var conversationReadPublisher: AnyPublisher<String, Never> {
        conversationReadSubject.eraseToAnyPublisher()
    }
    
    var readReceiptPublisher: AnyPublisher<String, Never> {
        readReceiptSubject.eraseToAnyPublisher()
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
    
    func connect(token: String, userId: String) {
        cachedToken = token
        cachedUserId = userId
        webSocketManager.connect(token: token, userId: userId)
    }
    
    func disconnect() {
        webSocketManager.disconnect()
    }
    
    // MARK: - Message Operations
    
    func loadMessagesAndConnect(otherUserId: String, token: String, userId: String, page: Int = 1, limit: Int = 50) async throws -> [Message] {
        activeConversations.insert(otherUserId)
        connect(token: token, userId: userId)
        
        let response = try await chatService.getMessageHistory(
            otherUserId: otherUserId,
            page: page,
            limit: limit,
            token: token,
            userId: userId
        )
        
        await messageStore.addMessages(response.messages, for: otherUserId)
        return response.messages
    }
    
    func loadMessages(otherUserId: String, token: String, userId: String, page: Int = 1, limit: Int = 50) async throws -> [Message] {
        let response = try await chatService.getMessageHistory(
            otherUserId: otherUserId,
            page: page,
            limit: limit,
            token: token,
            userId: userId
        )
        
        await messageStore.addMessages(response.messages, for: otherUserId)
        return response.messages
    }
    
    /// Send text message with optimistic UI update
    func sendMessage(receiverId: String, content: String, token: String, userId: String) async throws -> String {
        // Create temporary message for optimistic UI
        let temporaryId = UUID().uuidString
        let tempMessage = TemporaryMessage(
            temporaryId: temporaryId,
            receiverId: receiverId,
            content: content,
            timestamp: Date()
        )
        
        await messageStore.addTemporaryMessage(tempMessage)
        pendingTemporaryMessages[temporaryId] = receiverId
        
        let displayMessage = tempMessage.toDisplayMessage(senderId: userId)
        await messageStore.addMessage(displayMessage, for: receiverId)
        
        if case .connected = webSocketManager.connectionState {
            webSocketManager.sendMessage(receiverId: receiverId, content: content)
        } else {
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
    
    /// Send image message — upload first, then send via REST
    /// No optimistic UI since we must wait for upload to get URL
    func sendImageMessage(image: UIImage, receiverId: String, token: String, userId: String) async throws {
        // Step 1: Compress image (ChatRepository is @MainActor; jpegData is safe to call directly)
        let resized = image.resized(maxDimension: 1024)
        guard let jpeg = resized.jpegData(compressionQuality: 0.6) else {
            throw NetworkError.serverError("Failed to compress image")
        }
        
        // Step 2: Upload image → get URL
        let imageUrl = try await chatService.uploadChatImage(jpeg, token: token, userId: userId)
        
        // Step 3: Send message with imageUrl via REST
        let confirmedMessage = try await chatService.sendImageMessage(
            receiverId: receiverId,
            imageUrl: imageUrl,
            token: token,
            userId: userId
        )
        
        // Step 4: Add confirmed message directly to store
        await messageStore.addMessage(confirmedMessage, for: receiverId)
        
        // Step 5: Emit so ViewModel refreshes
        messageSubject.send((confirmedMessage, receiverId))
    }
    
    func getCachedMessages(for otherUserId: String) async -> [Message] {
        return await messageStore.getMessages(for: otherUserId)
    }
    
    func markAsRead(messageId: String, otherUserId: String, token: String, userId: String) async throws {
        await messageStore.updateReadStatus(messageId: messageId, for: otherUserId, read: true)
        
        if case .connected = webSocketManager.connectionState {
            webSocketManager.markAsRead(messageId: messageId)
        }
        
        try await chatService.markMessageAsRead(messageId: messageId, token: token, userId: userId)
    }
    
    func markConversationAsRead(otherUserId: String, token: String, userId: String) async throws {
        await messageStore.markAllAsRead(for: otherUserId, currentUserId: userId)
        try await chatService.markConversationAsRead(otherUserId: otherUserId, token: token, userId: userId)
        conversationReadSubject.send(otherUserId)
    }
    
    func sendTypingIndicator(receiverId: String) {
        guard case .connected = webSocketManager.connectionState else { return }
        webSocketManager.sendTypingIndicator(receiverId: receiverId)
    }
    
    func loadConversations(token: String, userId: String) async throws -> [Conversation] {
        return try await chatService.getConversations(token: token, userId: userId)
    }
    
    func recoverMessages(otherUserId: String, token: String, userId: String) async throws -> [Message] {
        guard let lastMessage = await messageStore.getLastMessage(for: otherUserId),
              let lastTimestamp = lastMessage.timestamp else {
            return try await loadMessages(otherUserId: otherUserId, token: token, userId: userId)
        }
        
        let response = try await chatService.getMessageHistory(
            otherUserId: otherUserId,
            page: 1,
            limit: 100,
            token: token,
            userId: userId
        )
        
        let newerMessages = response.messages.filter { message in
            guard let messageTimestamp = message.timestamp else { return false }
            return messageTimestamp > lastTimestamp
        }
        
        await messageStore.addMessages(newerMessages, for: otherUserId)
        return newerMessages
    }
    
    // MARK: - Private Methods
    
    private func reconcileTemporaryMessage(temporaryId: String, confirmedMessage: Message, receiverId: String) async {
        Logger.chat.debug("🔄 Reconciling temp message \(temporaryId) with confirmed \(confirmedMessage.id)")
        
        pendingTemporaryMessages.removeValue(forKey: temporaryId)
        
        let messageWithStatus = confirmedMessage.withLocalStatus(.sent)
        
        await messageStore.confirmTemporaryMessage(
            temporaryId: temporaryId,
            confirmedMessage: messageWithStatus,
            for: receiverId
        )
        
        Logger.chat.info("✅ Reconciliation complete: \(temporaryId) -> \(confirmedMessage.id)")
    }
    
    private func reconcileIncomingMessage(_ message: Message, conversationUserId: String) async -> Bool {
        for (tempId, receiverId) in pendingTemporaryMessages where receiverId == conversationUserId {
            if let tempMsg = await messageStore.getTemporaryMessage(id: tempId) {
                if tempMsg.content == message.content {
                    await reconcileTemporaryMessage(
                        temporaryId: tempId,
                        confirmedMessage: message,
                        receiverId: receiverId
                    )
                    return true
                }
            }
        }
        return false
    }
    
    private func setupWebSocketObservers() {
        webSocketManager.connectionStatePublisher
            .sink { [weak self] state in
                guard let self = self else { return }
                self.connectionState = state
                
                if case .connected = state {
                    Task { @MainActor in
                        guard let token = self.cachedToken,
                              let userId = self.cachedUserId else { return }
                        
                        for conversationUserId in self.activeConversations {
                            do {
                                let recovered = try await self.recoverMessages(
                                    otherUserId: conversationUserId,
                                    token: token,
                                    userId: userId
                                )
                                if !recovered.isEmpty {
                                    Logger.chat.info("Recovered \(recovered.count) messages for conversation: \(conversationUserId)")
                                }
                            } catch {
                                Logger.chat.error("Failed to recover messages for \(conversationUserId): \(error)")
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        webSocketManager.messagePublisher
            .sink { [weak self] message in
                guard let self = self else { return }
                
                Task { @MainActor in
                    guard let currentUserId = self.cachedUserId else { return }
                    
                    let conversationUserId = message.senderId == currentUserId ? message.receiverId : message.senderId
                    
                    let isReconciled = await self.reconcileIncomingMessage(message, conversationUserId: conversationUserId)
                    
                    if !isReconciled {
                        await self.messageStore.addMessage(message, for: conversationUserId)
                    }
                    
                    let messages = await self.messageStore.getMessages(for: conversationUserId)
                    if let reconciledMessage = messages.first(where: { $0.id == message.id }) {
                        self.messageSubject.send((reconciledMessage, conversationUserId))
                    } else {
                        self.messageSubject.send((message, conversationUserId))
                    }
                }
            }
            .store(in: &cancellables)
        
        webSocketManager.readReceiptPublisher
            .sink { [weak self] messageId in
                guard let self = self else { return }
                
                Task { @MainActor in
                    await self.updateReadReceiptForMessage(messageId: messageId)
                    self.readReceiptSubject.send(messageId)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateReadReceiptForMessage(messageId: String) async {
        if let conversationUserId = await messageStore.findConversation(forMessageId: messageId) {
            await messageStore.updateReadStatus(messageId: messageId, for: conversationUserId, read: true)
        }
    }
}
