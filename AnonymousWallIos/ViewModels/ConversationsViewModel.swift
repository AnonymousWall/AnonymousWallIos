//
//  ConversationsViewModel.swift (with debug logging)
//  AnonymousWallIos
//
//  ViewModel for conversations list screen
//

import SwiftUI
import Combine

@MainActor
class ConversationsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var conversations: [Conversation] = []
    @Published var isLoadingConversations = false
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0 {
        didSet {
            Logger.chat.info("📊 unreadCount changed from \(oldValue) to \(unreadCount)")
        }
    }
    
    // MARK: - Private Properties
    
    private let repository: ChatRepository
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(repository: ChatRepository) {
        self.repository = repository
        Logger.chat.info("🎬 ConversationsViewModel initialized")
        setupObservers()
    }
    
    deinit {
        Logger.chat.info("💀 ConversationsViewModel deinitialized")
        loadTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load conversations list
    func loadConversations(authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self = self else { return }
            
            isLoadingConversations = true
            errorMessage = nil
            
            do {
                let loadedConversations = try await repository.loadConversations(
                    token: token,
                    userId: userId
                )
                
                conversations = loadedConversations
                
                // Connect WebSocket for real-time updates
                repository.connect(token: token, userId: userId)
                
            } catch {
                // Don't show error for cancellation (e.g. when navigating away)
                if (error as? URLError)?.code == .cancelled ||
                   error is CancellationError {
                    Logger.chat.debug("loadConversations cancelled (navigating away)")
                } else {
                    errorMessage = "Failed to load conversations: \(error.localizedDescription)"
                    Logger.chat.error("Failed to load conversations: \(error)")
                }
            }
            
            isLoadingConversations = false
        }
    }
    
    /// Refresh conversations (pull-to-refresh)
    func refreshConversations(authState: AuthState) async {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self = self else { return }
            
            guard let token = authState.authToken,
                  let userId = authState.currentUser?.id else {
                return
            }
            
            do {
                let loadedConversations = try await repository.loadConversations(
                    token: token,
                    userId: userId
                )
                
                conversations = loadedConversations
                
            } catch {
                if (error as? URLError)?.code == .cancelled ||
                   error is CancellationError {
                    Logger.chat.debug("refreshConversations cancelled")
                } else {
                    errorMessage = "Failed to refresh conversations: \(error.localizedDescription)"
                    Logger.chat.error("Failed to refresh conversations: \(error)")
                }
            }
        }
        await loadTask?.value
    }
    
    /// Retry loading conversations
    func retry(authState: AuthState) {
        loadConversations(authState: authState)
    }
    
    /// Disconnect WebSocket when view disappears
    func disconnect() {
        Logger.chat.info("🔌 ConversationsViewModel disconnect called")
        repository.disconnect()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        Logger.chat.info("🔗 Setting up observers in ConversationsViewModel")
        
        // Observe unread count updates from WebSocket
        repository.unreadCountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self = self else { return }
                Logger.chat.info("📊 ViewModel received unread count from repository: \(count)")
                Logger.chat.info("📊 Current unreadCount before update: \(self.unreadCount)")
                self.unreadCount = count
                Logger.chat.info("📊 Current unreadCount after update: \(self.unreadCount)")
                
                // Force objectWillChange to fire (shouldn't be necessary but worth trying)
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        Logger.chat.info("📊 Subscribed to unreadCountPublisher, total subscriptions: \(cancellables.count)")
        
        // Observe new messages to update conversation list
        repository.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (message, conversationUserId) in
                guard let self = self else { return }
                
                Logger.chat.debug("📨 ViewModel received message for conversation: \(conversationUserId)")
                
                // Update the corresponding conversation
                if let index = self.conversations.firstIndex(where: { $0.userId == conversationUserId }) {
                    var updatedConversation = self.conversations[index]
                    
                    // Create updated conversation with new last message
                    let updatedConv = Conversation(
                        userId: updatedConversation.userId,
                        profileName: updatedConversation.profileName,
                        lastMessage: message,
                        unreadCount: message.readStatus ? updatedConversation.unreadCount : updatedConversation.unreadCount + 1
                    )
                    
                    // Remove old and insert at top (most recent)
                    self.conversations.remove(at: index)
                    self.conversations.insert(updatedConv, at: 0)
                } else {
                    // New conversation - fetch full list to get profile name
                    Logger.chat.info("New conversation detected: \(conversationUserId)")
                }
            }
            .store(in: &cancellables)
        
        // Observe conversation read events to reset unread count
        repository.conversationReadPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversationUserId in
                guard let self = self else { return }
                
                Logger.chat.debug("📖 ViewModel received conversationRead event for: \(conversationUserId)")
                
                // Find and update the conversation to reset unread count
                if let index = self.conversations.firstIndex(where: { $0.userId == conversationUserId }) {
                    let conversation = self.conversations[index]
                    let updatedConv = Conversation(
                        userId: conversation.userId,
                        profileName: conversation.profileName,
                        lastMessage: conversation.lastMessage,
                        unreadCount: 0  // Reset to 0
                    )
                    self.conversations[index] = updatedConv
                    Logger.chat.debug("📖 Updated conversation unreadCount to 0 for: \(conversationUserId)")
                }
            }
            .store(in: &cancellables)
    }
}
