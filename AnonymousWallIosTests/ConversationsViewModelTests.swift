//
//  ConversationsViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for ConversationsViewModel - conversation list management
//

import Testing
import Combine
@testable import AnonymousWallIos

@MainActor
struct ConversationsViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let viewModel = createTestViewModel()
        
        #expect(viewModel.conversations.isEmpty)
        #expect(viewModel.isLoadingConversations == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.unreadCount == 0)
    }
    
    // MARK: - Conversation Read Event Tests
    
    @Test func testClearUnreadCountForConversation() async throws {
        let viewModel = createTestViewModel()
        
        // Manually add a conversation with unread count
        let conversation = Conversation(
            userId: "user2",
            profileName: "Test User",
            lastMessage: nil,
            unreadCount: 5
        )
        viewModel.conversations = [conversation]
        
        // Clear unread count
        viewModel.clearUnreadCount(for: "user2")
        
        // Verify unread count is now 0
        #expect(viewModel.conversations[0].unreadCount == 0)
    }
    
    @Test func testClearUnreadCountForNonExistentConversation() async throws {
        let viewModel = createTestViewModel()
        
        // Add a conversation
        let conversation = Conversation(
            userId: "user2",
            profileName: "Test User",
            lastMessage: nil,
            unreadCount: 5
        )
        viewModel.conversations = [conversation]
        
        // Try to clear unread count for non-existent user
        viewModel.clearUnreadCount(for: "user999")
        
        // Verify original conversation is unchanged
        #expect(viewModel.conversations[0].unreadCount == 5)
    }
    
    @Test func testObserveConversationReadEvent() async throws {
        let (viewModel, mockService, mockWebSocket) = createTestViewModelWithMocks()
        let authState = createMockAuthState()
        
        // Setup mock conversations
        let conversation = Conversation(
            userId: "user2",
            profileName: "Test User",
            lastMessage: nil,
            unreadCount: 3
        )
        mockService.mockConversations = [conversation]
        
        // Load conversations
        viewModel.loadConversations(authState: authState)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify conversation loaded with unread count
        #expect(viewModel.conversations.count == 1)
        #expect(viewModel.conversations[0].unreadCount == 3)
        
        // Simulate marking conversation as read via the repository
        // This would normally happen when user opens ChatView
        // We'll simulate it by directly calling clearUnreadCount
        viewModel.clearUnreadCount(for: "user2")
        
        // Verify unread count cleared
        #expect(viewModel.conversations[0].unreadCount == 0)
    }
    
    // MARK: - Test Helpers
    
    private func createTestViewModel() -> ConversationsViewModel {
        let mockService = MockChatService()
        let mockWebSocket = MockWebSocketManager()
        let messageStore = MessageStore()
        
        let repository = ChatRepository(
            chatService: mockService,
            webSocketManager: mockWebSocket,
            messageStore: messageStore
        )
        
        return ConversationsViewModel(repository: repository)
    }
    
    private func createTestViewModelWithMocks() -> (ConversationsViewModel, MockChatService, MockWebSocketManager) {
        let mockService = MockChatService()
        let mockWebSocket = MockWebSocketManager()
        let messageStore = MessageStore()
        
        let repository = ChatRepository(
            chatService: mockService,
            webSocketManager: mockWebSocket,
            messageStore: messageStore
        )
        
        let viewModel = ConversationsViewModel(repository: repository)
        
        return (viewModel, mockService, mockWebSocket)
    }
    
    private func createMockAuthState() -> AuthState {
        let authState = AuthState()
        let mockUser = User(
            id: "user1",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01T00:00:00Z"
        )
        authState.currentUser = mockUser
        authState.authToken = "test-token"
        return authState
    }
}
