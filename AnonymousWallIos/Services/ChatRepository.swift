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
class ChatRepository: ChatRepositoryProtocol {
    
    // MARK: - Properties
    
    private let chatService: ChatAPIServiceProtocol
    private let webSocketManager: ChatWebSocketManagerProtocol
    private let messageStore: MessageStore
    private let mediaService: MediaServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var tokenRefreshObserver: NSObjectProtocol?
    
    private var pendingTemporaryMessages: [String: String] = [:]
    private var activeConversations: Set<String> = []
    private var shouldMaintainConnection = false
    private var cachedToken: String?
    private var cachedUserId: String?
    
    private var conversationReadSubject = PassthroughSubject<String, Never>()
    private var readReceiptSubject = PassthroughSubject<String, Never>()
    private var messageSubject = PassthroughSubject<(Message, String), Never>()
    
    @Published private(set) var connectionState: WebSocketConnectionState = .disconnected
    
    var messagePublisher: AnyPublisher<(Message, String), Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var typingPublisher: AnyPublisher<String, Never> {
        webSocketManager.typingPublisher
    }
    
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> {
        $connectionState.eraseToAnyPublisher()
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
        chatService: ChatAPIServiceProtocol = ChatAPIService.shared,
        webSocketManager: ChatWebSocketManagerProtocol,
        messageStore: MessageStore,
        mediaService: MediaServiceProtocol = MediaService.shared
    ) {
        self.chatService = chatService
        self.webSocketManager = webSocketManager
        self.messageStore = messageStore
        self.mediaService = mediaService
        
        setupWebSocketObservers()
    }

    deinit {
        if let tokenRefreshObserver {
            NotificationCenter.default.removeObserver(tokenRefreshObserver)
        }
    }
    
    // MARK: - Connection Management
    
    func connect(token: String, userId: String) {
        cachedToken = token
        cachedUserId = userId
        shouldMaintainConnection = true
        webSocketManager.connect(token: token, userId: userId)
    }
    
    func disconnect() {
        shouldMaintainConnection = false
        webSocketManager.disconnect()
    }

    func updateCachedToken(_ token: String) {
        cachedToken = token
        webSocketManager.updateToken(token)

        guard shouldMaintainConnection, let userId = cachedUserId else { return }

        switch webSocketManager.connectionState {
        case .disconnected, .failed, .reconnecting:
            webSocketManager.connect(token: token, userId: userId)
        default:
            break
        }
    }
    
    func disconnectForBackground() {
        shouldMaintainConnection = false
        webSocketManager.disconnect()
    }
    
    func reconnectForForeground() {
        guard let token = cachedToken, let userId = cachedUserId else { return }
        connect(token: token, userId: userId)
    }
    
    // MARK: - Message Operations
    
    func loadMessagesAndConnect(otherUserId: String, token: String, userId: String, page: Int = 1, limit: Int = 50) async throws -> MessageHistoryResponse {
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
        return response
    }
    
    func loadMessages(otherUserId: String, token: String, userId: String, page: Int = 1, limit: Int = 50) async throws -> MessageHistoryResponse {
        let response = try await chatService.getMessageHistory(
            otherUserId: otherUserId,
            page: page,
            limit: limit,
            token: token,
            userId: userId
        )

        await messageStore.addMessages(response.messages, for: otherUserId)
        return response
    }
    
    func sendMessage(receiverId: String, content: String, token: String, userId: String) async throws -> String {
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
                    messageSubject.send((confirmedMessage, receiverId))
                } catch {
                    await messageStore.updateLocalStatus(
                        messageId: temporaryId,
                        for: receiverId,
                        status: .failed
                    )
                    pendingTemporaryMessages.removeValue(forKey: temporaryId)
                    let updatedMessages = await messageStore.getMessages(for: receiverId)
                    if let failedMessage = updatedMessages.first(where: { $0.id == temporaryId }) {
                        messageSubject.send((failedMessage, receiverId))
                    }
                }
            }
        }
        
        return temporaryId
    }
    
    /// Send image message — presign + upload directly to OCI, then send objectName via REST
    func sendImageMessage(image: UIImage, receiverId: String, token: String, userId: String) async throws {
        let objectName = try await mediaService.uploadImage(image, folder: "chat", token: token)

        let confirmedMessage = try await chatService.sendImageMessage(
            receiverId: receiverId,
            imageObjectName: objectName,
            token: token,
            userId: userId
        )

        await messageStore.addMessage(confirmedMessage, for: receiverId)
        messageSubject.send((confirmedMessage, receiverId))
    }
    
    func getCachedMessages(for otherUserId: String) async -> [Message] {
        return await messageStore.getMessages(for: otherUserId)
    }
    
    func leaveConversation(otherUserId: String) {
        activeConversations.remove(otherUserId)
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
        guard await messageStore.getLastMessage(for: otherUserId) != nil else {
            let response = try await loadMessages(otherUserId: otherUserId, token: token, userId: userId)
            return response.messages
        }

        let response = try await chatService.getMessageHistory(
            otherUserId: otherUserId,
            page: 1,
            limit: 100,
            token: token,
            userId: userId
        )

        // Snapshot existing IDs before the merge so we can identify genuinely new
        // messages for publishing, while still letting addMessages apply any
        // read-status updates to already-cached messages (e.g. messages that were
        // read by the recipient while this device was disconnected / token-refreshing).
        let existingIds = Set(await messageStore.getMessages(for: otherUserId).map { $0.id })
        await messageStore.addMessages(response.messages, for: otherUserId)
        let newMessages = response.messages.filter { !existingIds.contains($0.id) }
        return newMessages
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
                                    for message in recovered {
                                        self.messageSubject.send((message, conversationUserId))
                                    }
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

        tokenRefreshObserver = NotificationCenter.default.addObserver(
            forName: .tokenRefreshed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let newToken = notification.userInfo?["token"] as? String else { return }
            self.updateCachedToken(newToken)
        }
        
        webSocketManager.sendFailurePublisher
            .sink { [weak self] (receiverId, content) in
                guard let self else { return }
                // Find the pending temp message for this content+receiver and mark it failed,
                // then retry via REST so the message is not silently lost.
                Task { @MainActor in
                    guard let token = self.cachedToken,
                          let userId = self.cachedUserId else { return }
                    var candidateTempIds: [String] = []
                    for (tempId, tempReceiverId) in self.pendingTemporaryMessages where tempReceiverId == receiverId {
                        if await self.messageStore.getTemporaryMessage(id: tempId)?.content == content {
                            candidateTempIds.append(tempId)
                        }
                    }
                    // Ambiguous or missing mapping — skip automatic recovery to avoid
                    // reconciling the wrong message when multiple pending messages share
                    // the same (receiverId, content) pair.
                    guard candidateTempIds.count == 1, let temporaryId = candidateTempIds.first else { return }
                    do {
                        let confirmedMessage = try await self.chatService.sendMessage(
                            receiverId: receiverId,
                            content: content,
                            token: token,
                            userId: userId
                        )
                        await self.reconcileTemporaryMessage(
                            temporaryId: temporaryId,
                            confirmedMessage: confirmedMessage,
                            receiverId: receiverId
                        )
                        self.messageSubject.send((confirmedMessage, receiverId))
                    } catch {
                        await self.messageStore.updateLocalStatus(
                            messageId: temporaryId,
                            for: receiverId,
                            status: .failed
                        )
                        self.pendingTemporaryMessages.removeValue(forKey: temporaryId)
                        let messages = await self.messageStore.getMessages(for: receiverId)
                        if let failedMessage = messages.first(where: { $0.id == temporaryId }) {
                            self.messageSubject.send((failedMessage, receiverId))
                        }
                    }
                }
            }
            .store(in: &cancellables)

        webSocketManager.tokenRefreshNeededPublisher
            .sink { [weak self] in
                guard let self else { return }
                Logger.chat.info("WebSocket requested token refresh — triggering immediately")
                Task {
                    let result = await NetworkClient.shared.refreshAccessToken()
                    if result == false {
                        Logger.auth.warning("Token refresh failed during WebSocket recovery — logout expected")
                    }
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
