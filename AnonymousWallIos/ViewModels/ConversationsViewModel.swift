//
//  ConversationsViewModel.swift
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
    @Published var unreadCount: Int = 0
    
    // MARK: - Private Properties
    
    private let repository: ChatRepository
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(repository: ChatRepository) {
        self.repository = repository
        setupObservers()
    }
    
    deinit {
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
                errorMessage = "Failed to load conversations: \(error.localizedDescription)"
                Logger.chat.error("Failed to load conversations: \(error)")
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
                errorMessage = "Failed to refresh conversations: \(error.localizedDescription)"
                Logger.chat.error("Failed to refresh conversations: \(error)")
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
        repository.disconnect()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe unread count updates from WebSocket
        repository.unreadCountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.unreadCount = count
            }
            .store(in: &cancellables)
        
        // Observe new messages to update conversation list
        repository.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (message, conversationUserId) in
                guard let self = self else { return }
                
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
                    // In production, you might want to debounce this or handle it differently
                    Logger.chat.info("New conversation detected: \(conversationUserId)")
                }
            }
            .store(in: &cancellables)
    }
}
