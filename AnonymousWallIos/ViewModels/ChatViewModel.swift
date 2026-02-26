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
    @Published var isUploadingImage = false
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
    
    func loadMessages(authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        currentAuthState = authState
        
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self = self else { return }
            
            isLoadingMessages = true
            errorMessage = nil
            
            do {
                let loadedMessages = try await repository.loadMessagesAndConnect(
                    otherUserId: otherUserId,
                    token: token,
                    userId: userId,
                    page: 1,
                    limit: 50
                )
                messages = loadedMessages
            } catch {
                errorMessage = "Failed to load messages: \(error.localizedDescription)"
                Logger.chat.error("Failed to load messages: \(error)")
            }
            
            isLoadingMessages = false
        }
    }
    
    /// Send a text message
    func sendMessage(authState: AuthState) {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        let content = messageText
        messageText = ""
        
        Task { [weak self] in
            guard let self = self else { return }
            isSendingMessage = true
            do {
                let _ = try await repository.sendMessage(
                    receiverId: otherUserId,
                    content: content,
                    token: token,
                    userId: userId
                )
                await refreshMessagesFromStore()
            } catch {
                errorMessage = "Failed to send message: \(error.localizedDescription)"
                Logger.chat.error("Failed to send message: \(error)")
            }
            isSendingMessage = false
        }
    }
    
    /// Send an image message
    func sendImage(_ image: UIImage, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            isUploadingImage = true
            do {
                try await repository.sendImageMessage(
                    image: image,
                    receiverId: otherUserId,
                    token: token,
                    userId: userId
                )
                await refreshMessagesFromStore()
            } catch {
                errorMessage = "Failed to send image: \(error.localizedDescription)"
                Logger.chat.error("Failed to send image: \(error)")
            }
            isUploadingImage = false
        }
    }
    
    func markAsRead(messageId: String, authState: AuthState, refreshStore: Bool = true) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await repository.markAsRead(
                    messageId: messageId,
                    otherUserId: otherUserId,
                    token: token,
                    userId: userId
                )
                if refreshStore {
                    await refreshMessagesFromStore()
                }
            } catch {
                Logger.chat.error("Failed to mark message as read: \(error)")
            }
        }
    }
    
    func markConversationAsRead(authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await repository.markConversationAsRead(
                    otherUserId: otherUserId,
                    token: token,
                    userId: userId
                )
                await refreshMessagesFromStore()
            } catch {
                Logger.chat.error("Failed to mark conversation as read: \(error)")
            }
        }
    }
    
    func sendTypingIndicator() {
        repository.sendTypingIndicator(receiverId: otherUserId)
    }
    
    func onTextChanged() {
        typingTimer?.invalidate()
        sendTypingIndicator()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in }
    }
    
    func viewDidAppear() {
        isViewActive = true
    }
    
    func disconnect() {
        isViewActive = false
    }
    
    func retry(authState: AuthState) {
        loadMessages(authState: authState)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        repository.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
        
        repository.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (message, conversationUserId) in
                guard let self = self else { return }
                
                if conversationUserId == self.otherUserId {
                    Task {
                        await self.refreshMessagesFromStore()
                        
                        if self.isViewActive && message.senderId == self.otherUserId && !message.readStatus,
                           let authState = self.currentAuthState {
                            self.markAsRead(messageId: message.id, authState: authState, refreshStore: false)
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        repository.typingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] senderId in
                guard let self = self else { return }
                if senderId == self.otherUserId {
                    self.isTyping = true
                    Task { [weak self] in
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        self?.isTyping = false
                    }
                }
            }
            .store(in: &cancellables)
        
        repository.readReceiptPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { await self.refreshMessagesFromStore() }
            }
            .store(in: &cancellables)
    }
    
    private func refreshMessagesFromStore() async {
        let storedMessages = await messageStore.getMessages(for: otherUserId)
        
        #if DEBUG
        validateMessageOrdering(storedMessages)
        #endif
        
        messages = storedMessages
    }
    
    #if DEBUG
    private func validateMessageOrdering(_ messages: [Message]) {
        guard messages.count > 1 else { return }
        for i in 0..<(messages.count - 1) {
            let current = messages[i]
            let next = messages[i + 1]
            guard let currentTime = current.timestamp,
                  let nextTime = next.timestamp else { continue }
            if currentTime > nextTime {
                Logger.chat.error("Message ordering violation: \(current.id) > \(next.id)")
            }
        }
    }
    #endif
}
