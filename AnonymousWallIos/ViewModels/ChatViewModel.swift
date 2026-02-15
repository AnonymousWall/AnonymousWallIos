//
//  ChatViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for chat conversation screen
//

import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var messages: [Message] = []
    @Published var isLoadingMessages = false
    @Published var isLoadingMore = false
    @Published var isSendingMessage = false
    @Published var errorMessage: String?
    @Published var messageText: String = ""
    @Published var connectionState: WebSocketConnectionState = .disconnected
    @Published var isTyping = false
    
    /// Version number that increments when messages array changes, forcing SwiftUI to rebuild
    @Published var messagesVersion = UUID()
    
    // MARK: - Private Properties
    
    private let repository: ChatRepository
    private let messageStore: MessageStore
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    private var typingTimer: Timer?
    
    /// Track if view is currently active (on screen)
    private var isViewActive = false
    
    /// The other user's ID (conversation partner)
    let otherUserId: String
    let otherUserName: String
    
    // MARK: - Initialization
    
    init(
        otherUserId: String,
        otherUserName: String,
        repository: ChatRepository,
        messageStore: MessageStore
    ) {
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName
        self.repository = repository
        self.messageStore = messageStore
        
        setupObservers()
    }
    
    deinit {
        loadTask?.cancel()
        typingTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Load messages and connect to WebSocket
    func loadMessages(authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self = self else { return }
            
            isLoadingMessages = true
            errorMessage = nil
            
            do {
                // Load initial messages via REST
                let loadedMessages = try await repository.loadMessages(
                    otherUserId: otherUserId,
                    token: token,
                    userId: userId,
                    page: 1,
                    limit: 50
                )
                
                // Update UI
                messages = loadedMessages
                
                // Connect WebSocket for real-time updates
                repository.connect(token: token, userId: userId)
                
            } catch {
                errorMessage = "Failed to load messages: \(error.localizedDescription)"
                Logger.chat.error("Failed to load messages: \(error)")
            }
            
            isLoadingMessages = false
        }
    }
    
    /// Send a message
    func sendMessage(authState: AuthState) {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        let content = messageText
        messageText = "" // Clear input immediately
        
        Task { [weak self] in
            guard let self = self else { return }
            
            isSendingMessage = true
            
            do {
                // Send message with optimistic UI
                let tempId = try await repository.sendMessage(
                    receiverId: otherUserId,
                    content: content,
                    token: token,
                    userId: userId
                )
                
                // Refresh messages from store
                await refreshMessagesFromStore()
                
            } catch {
                errorMessage = "Failed to send message: \(error.localizedDescription)"
                Logger.chat.error("Failed to send message: \(error)")
            }
            
            isSendingMessage = false
        }
    }
    
    /// Mark message as read
    func markAsRead(messageId: String, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await repository.markAsRead(
                    messageId: messageId,
                    otherUserId: otherUserId,
                    token: token,
                    userId: userId
                )
                
                // Refresh messages from store
                await refreshMessagesFromStore()
                
            } catch {
                Logger.chat.error("Failed to mark message as read: \(error)")
            }
        }
    }
    
    /// Mark entire conversation as read
    func markConversationAsRead(authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await repository.markConversationAsRead(
                    otherUserId: otherUserId,
                    token: token,
                    userId: userId
                )
                
                // Refresh messages from store
                await refreshMessagesFromStore()
                
            } catch {
                Logger.chat.error("Failed to mark conversation as read: \(error)")
            }
        }
    }
    
    /// Send typing indicator
    func sendTypingIndicator() {
        repository.sendTypingIndicator(receiverId: otherUserId)
    }
    
    /// Handle text input change
    func onTextChanged() {
        // Send typing indicator (throttled)
        typingTimer?.invalidate()
        sendTypingIndicator()
        
        // Stop indicating after 2 seconds of no typing
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            // Typing stopped
        }
    }
    
    /// Called when view appears
    func viewDidAppear() {
        isViewActive = true
        Logger.chat.info("ChatView became active for user: \(otherUserId)")
    }
    
    /// Called when view disappears
    func viewWillDisappear() {
        isViewActive = false
        Logger.chat.info("ChatView became inactive for user: \(otherUserId)")
    }
    
    /// Disconnect WebSocket when view disappears
    func disconnect() {
        repository.disconnect()
    }
    
    /// Retry loading messages
    func retry(authState: AuthState) {
        loadMessages(authState: authState)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe connection state
        repository.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
        
        // Observe incoming messages
        repository.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (message, conversationUserId) in
                guard let self = self else { return }
                
                // Only handle messages for this conversation
                if conversationUserId == self.otherUserId {
                    Task { [weak self] in
                        guard let self = self else { return }
                        
                        await self.refreshMessagesFromStore()
                        
                        // Auto-mark as read if view is active and message is from other user
                        if self.isViewActive && message.senderId == self.otherUserId && !message.readStatus {
                            Logger.chat.info("Auto-marking message as read (view is active): \(message.id)")
                            
                            // Get auth state - we need to pass this from the view
                            // For now, mark locally and send read receipt via WebSocket
                            await self.messageStore.updateReadStatus(
                                messageId: message.id,
                                for: self.otherUserId,
                                read: true
                            )
                            
                            // Send read receipt via WebSocket
                            self.repository.sendReadReceipt(messageId: message.id)
                            
                            // Refresh to update UI
                            await self.refreshMessagesFromStore()
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe typing indicators
        repository.typingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] senderId in
                guard let self = self else { return }
                
                // Only show typing for this conversation
                if senderId == self.otherUserId {
                    self.isTyping = true
                    
                    // Hide typing indicator after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.isTyping = false
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe read receipts
        repository.readReceiptPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messageId in
                guard let self = self else { return }
                
                Task {
                    await self.refreshMessagesFromStore()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshMessagesFromStore() async {
        let storedMessages = await messageStore.getMessages(for: otherUserId)
        Logger.chat.info("ChatViewModel: Refreshing messages for \(otherUserId), count: \(storedMessages.count)")
        for (index, msg) in storedMessages.enumerated() {
            Logger.chat.debug("  [\(index)] id=\(msg.id) time=\(msg.createdAt) sender=\(msg.senderId) read=\(msg.readStatus)")
        }
        messages = storedMessages
        // Increment version to force SwiftUI to rebuild the message list
        messagesVersion = UUID()
    }
}
