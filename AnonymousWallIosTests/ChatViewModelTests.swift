//
//  ChatViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for ChatViewModel - message loading, sending, WebSocket integration
//

import Testing
import Combine
@testable import AnonymousWallIos

@MainActor
struct ChatViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let (viewModel, _, _) = createTestViewModel()
        
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.isLoadingMessages == false)
        #expect(viewModel.isSendingMessage == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.messageText.isEmpty)
        #expect(viewModel.isTyping == false)
        #expect(viewModel.otherUserId == "user2")
        #expect(viewModel.otherUserName == "Test User")
    }
    
    // MARK: - Load Messages Tests
    
    @Test func testLoadMessagesSuccess() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Setup mock data
        mockService.mockMessages = [
            createMockMessage(id: "msg1", senderId: "user2", receiverId: "user1"),
            createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2")
        ]
        
        // Execute
        viewModel.loadMessages(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify
        #expect(mockService.getMessageHistoryCalled == true)
        #expect(viewModel.messages.count == 2)
        #expect(viewModel.isLoadingMessages == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testLoadMessagesFailure() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Configure to fail
        mockService.getMessageHistoryBehavior = .failure(MockChatService.MockError.networkError)
        
        // Execute
        viewModel.loadMessages(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify
        #expect(mockService.getMessageHistoryCalled == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoadingMessages == false)
    }
    
    @Test func testLoadMessagesWithoutAuth() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = AuthState() // No auth
        
        // Execute
        viewModel.loadMessages(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify
        #expect(mockService.getMessageHistoryCalled == false)
        #expect(viewModel.errorMessage == "Authentication required")
    }
    
    // MARK: - Send Message Tests
    
    @Test func testSendMessageSuccess() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Set message text
        viewModel.messageText = "Hello, World!"
        
        // Execute
        viewModel.sendMessage(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify
        #expect(mockService.sendMessageCalled == true)
        #expect(viewModel.messageText.isEmpty) // Should be cleared
        #expect(viewModel.isSendingMessage == false)
    }
    
    @Test func testSendEmptyMessageIgnored() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Set empty message
        viewModel.messageText = "   "
        
        // Execute
        viewModel.sendMessage(authState: authState)
        
        // Wait
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify - should not call service
        #expect(mockService.sendMessageCalled == false)
    }
    
    @Test func testSendMessageWithoutAuth() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = AuthState() // No auth
        
        viewModel.messageText = "Hello"
        
        // Execute
        viewModel.sendMessage(authState: authState)
        
        // Wait
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify
        #expect(mockService.sendMessageCalled == false)
        #expect(viewModel.errorMessage == "Authentication required")
    }
    
    // MARK: - Mark as Read Tests
    
    @Test func testMarkMessageAsRead() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Execute
        viewModel.markAsRead(messageId: "msg1", authState: authState)
        
        // Wait
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify
        #expect(mockService.markMessageAsReadCalled == true)
    }
    
    @Test func testMarkConversationAsRead() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Execute
        viewModel.markConversationAsRead(authState: authState)
        
        // Wait
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify
        #expect(mockService.markConversationAsReadCalled == true)
    }
    
    // MARK: - WebSocket Integration Tests
    
    @Test func testWebSocketConnectionState() async throws {
        let (viewModel, _, mockWebSocket) = createTestViewModel()
        
        // Initially disconnected
        #expect(viewModel.connectionState == .disconnected)
        
        // Simulate connection
        mockWebSocket.connect(token: "test-token", userId: "user1")
        
        // Wait for state update
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify connected
        #expect(viewModel.connectionState == .connected)
    }
    
    @Test func testReceiveMessageViaWebSocket() async throws {
        let (viewModel, _, mockWebSocket) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Load initial messages
        viewModel.loadMessages(authState: authState)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let initialCount = viewModel.messages.count
        
        // Simulate receiving a message via WebSocket
        let newMessage = createMockMessage(id: "ws-msg-1", senderId: "user2", receiverId: "user1")
        mockWebSocket.simulateReceiveMessage(newMessage)
        
        // Wait for update
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify message added
        #expect(viewModel.messages.count > initialCount)
    }
    
    @Test func testTypingIndicator() async throws {
        let (viewModel, _, mockWebSocket) = createTestViewModel()
        
        // Initially not typing
        #expect(viewModel.isTyping == false)
        
        // Simulate typing indicator
        mockWebSocket.simulateTyping(from: "user2")
        
        // Wait for update
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify typing indicator shown
        #expect(viewModel.isTyping == true)
    }
    
    @Test func testSendTypingIndicator() async throws {
        let (viewModel, _, mockWebSocket) = createTestViewModel()
        
        // Execute
        viewModel.sendTypingIndicator()
        
        // Verify
        #expect(mockWebSocket.sendTypingIndicatorCalled == true)
        #expect(mockWebSocket.lastTypingReceiverId == "user2")
    }
    
    @Test func testOnTextChangedSendsTypingIndicator() async throws {
        let (viewModel, _, mockWebSocket) = createTestViewModel()
        
        // Execute
        viewModel.onTextChanged()
        
        // Verify
        #expect(mockWebSocket.sendTypingIndicatorCalled == true)
    }
    
    // MARK: - Disconnect Tests
    
    @Test func testDisconnect() async throws {
        let (viewModel, _, mockWebSocket) = createTestViewModel()
        
        // Connect first
        mockWebSocket.connect(token: "test-token", userId: "user1")
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Disconnect
        viewModel.disconnect()
        
        // Verify
        #expect(mockWebSocket.disconnectCalled == true)
    }
    
    // MARK: - Retry Tests
    
    @Test func testRetryAfterError() async throws {
        let (viewModel, mockService, _) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Set error
        viewModel.errorMessage = "Test error"
        
        // Retry
        viewModel.retry(authState: authState)
        
        // Wait
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify loadMessages called again
        #expect(mockService.getMessageHistoryCalled == true)
    }
    
    // MARK: - View Lifecycle Tests
    
    @Test func testViewLifecycleTracking() async throws {
        let (viewModel, _, _) = createTestViewModel()
        
        // Initially inactive
        // Note: isViewActive is private, so we test via behavior
        
        // Simulate view appearing
        viewModel.viewDidAppear()
        
        // Simulate view disappearing
        viewModel.viewWillDisappear()
        
        // Test passes if no errors occur
    }
    
    @Test func testAutoMarkAsReadWhenViewIsActive() async throws {
        let (viewModel, mockService, mockWebSocket) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Setup mock data
        mockService.mockMessages = []
        
        // Load messages to establish connection
        viewModel.loadMessages(authState: authState)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Mark view as active
        viewModel.viewDidAppear()
        
        // Simulate receiving a message from the other user while view is active
        let incomingMessage = createMockMessage(id: "new-msg", senderId: "user2", receiverId: "user1")
        mockWebSocket.simulateReceiveMessage(incomingMessage)
        
        // Wait for auto-mark-as-read to process
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Verify read receipt was sent via WebSocket
        #expect(mockWebSocket.markAsReadCalled == true)
        #expect(mockWebSocket.lastMarkReadMessageId == "new-msg")
    }
    
    @Test func testDoNotAutoMarkAsReadWhenViewIsInactive() async throws {
        let (viewModel, mockService, mockWebSocket) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Setup mock data
        mockService.mockMessages = []
        
        // Load messages to establish connection
        viewModel.loadMessages(authState: authState)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Mark view as active then immediately inactive
        viewModel.viewDidAppear()
        viewModel.viewWillDisappear()
        
        // Reset the mock to clear previous calls
        mockWebSocket.reset()
        mockWebSocket.connect(token: "test", userId: "user1")
        
        // Simulate receiving a message from the other user while view is inactive
        let incomingMessage = createMockMessage(id: "new-msg-2", senderId: "user2", receiverId: "user1")
        mockWebSocket.simulateReceiveMessage(incomingMessage)
        
        // Wait for potential auto-mark-as-read (should not happen)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Verify read receipt was NOT sent (view is inactive)
        #expect(mockWebSocket.markAsReadCalled == false)
    }
    
    @Test func testDoNotAutoMarkAsReadForOwnMessages() async throws {
        let (viewModel, mockService, mockWebSocket) = createTestViewModel()
        let authState = createMockAuthState()
        
        // Setup mock data
        mockService.mockMessages = []
        
        // Load messages and mark view as active
        viewModel.loadMessages(authState: authState)
        try await Task.sleep(nanoseconds: 200_000_000)
        viewModel.viewDidAppear()
        
        // Reset mock to clear previous calls
        mockWebSocket.markAsReadCalled = false
        mockWebSocket.lastMarkReadMessageId = nil
        
        // Simulate receiving our own message (sent by user1)
        let ownMessage = createMockMessage(id: "own-msg", senderId: "user1", receiverId: "user2")
        mockWebSocket.simulateReceiveMessage(ownMessage)
        
        // Wait
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Verify read receipt was NOT sent (it's our own message)
        #expect(mockWebSocket.markAsReadCalled == false)
    }
    
    // MARK: - Test Helpers
    
    private func createTestViewModel() -> (ChatViewModel, MockChatService, MockWebSocketManager) {
        let mockService = MockChatService()
        let mockWebSocket = MockWebSocketManager()
        let messageStore = MessageStore()
        
        let repository = ChatRepository(
            chatService: mockService,
            webSocketManager: mockWebSocket,
            messageStore: messageStore
        )
        
        let viewModel = ChatViewModel(
            otherUserId: "user2",
            otherUserName: "Test User",
            repository: repository,
            messageStore: messageStore
        )
        
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
    
    private func createMockMessage(
        id: String,
        senderId: String,
        receiverId: String,
        content: String = "Test message"
    ) -> Message {
        return Message(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            readStatus: false,
            createdAt: "2026-02-15T12:00:00Z"
        )
    }
}
