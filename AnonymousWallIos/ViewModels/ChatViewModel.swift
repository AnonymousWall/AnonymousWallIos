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
    
    // MARK: - Private Properties
    
    private let repository: ChatRepository
    private let messageStore: MessageStore
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    private var typingTimer: Timer?
    private var isViewActive = false
    private var currentAuthState: AuthState?
    
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
        
        // Store auth state for auto-marking messages as read
        currentAuthState = authState
        
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self = self else { return }
            
            isLoadingMessages = true
            errorMessage = nil
            
            do {
                // Atomically load messages and connect WebSocket to avoid race condition
                let loadedMessages = try await repository.loadMessagesAndConnect(
                    otherUserId: otherUserId,
                    token: token,
                    userId: userId,
                    page: 1,
                    limit: 50
                )
                
                // Update UI
                messages = loadedMessages
                
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
    /// - Parameters:
    ///   - messageId: Message ID
    ///   - authState: Auth state
    ///   - refreshStore: Whether to refresh messages from store after (default: true)
    func markAsRead(messageId: String, authState: AuthState, refreshStore: Bool = true) {
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
                
                // Conditionally refresh messages from store
                if refreshStore {
                    await refreshMessagesFromStore()
                }
                
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
    }
    
    /// Disconnect WebSocket when view disappears
    func disconnect() {
        isViewActive = false
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
                    Task {
                        await self.refreshMessagesFromStore()
                        
                        // Auto-mark as read if view is active and message is from other user
                        if self.isViewActive && message.senderId == self.otherUserId && !message.readStatus,
                           let authState = self.currentAuthState {
                            // Mark as read without refreshing again (we just refreshed above)
                            self.markAsRead(messageId: message.id, authState: authState, refreshStore: false)
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
        
        // Validate ordering in debug mode
        #if DEBUG
        validateMessageOrdering(storedMessages)
        #endif
        
        messages = storedMessages
    }
    
    #if DEBUG
    /// Validate that messages are properly ordered
    private func validateMessageOrdering(_ messages: [Message]) {
        guard messages.count > 1 else { return }
        
        for i in 0..<(messages.count - 1) {
            let current = messages[i]
            let next = messages[i + 1]
            
            guard let currentTime = current.timestamp,
                  let nextTime = next.timestamp else {
                continue
            }
            
            if currentTime > nextTime {
                Logger.chat.error("Message ordering violation detected: \(current.id) > \(next.id)")
            }
        }
    }
    #endif
}
