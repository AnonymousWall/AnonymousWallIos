//
//  ChatRepositorySendFailureTests.swift
//  AnonymousWallIosTests
//
//  Tests for ChatRepository WebSocket send-failure recovery:
//  REST retry, ambiguous-content skip, and failure → .failed marking.
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct ChatRepositorySendFailureTests {

    // MARK: - Helpers

    private func makeRepository() -> (ChatRepository, MockChatService, MockWebSocketManager, MessageStore) {
        let mockService = MockChatService()
        let mockWebSocket = MockWebSocketManager()
        let messageStore = MessageStore()
        let repository = ChatRepository(
            chatService: mockService,
            webSocketManager: mockWebSocket,
            messageStore: messageStore
        )
        return (repository, mockService, mockWebSocket, messageStore)
    }

    /// Connects the repository and waits for the WebSocket to reach .connected.
    private func connectAndWait(_ repository: ChatRepository) async throws {
        repository.connect(token: "test-token", userId: "user1")
        // MockWebSocketManager transitions to .connected after 0.1 s
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    // MARK: - REST Retry Tests

    @Test func testSendFailureTriggersRESTRetryOnSuccess() async throws {
        let (repository, mockService, mockWebSocket, _) = makeRepository()
        try await connectAndWait(repository)

        // Send via WebSocket (optimistic)
        _ = try await repository.sendMessage(
            receiverId: "user2",
            content: "Hello",
            token: "test-token",
            userId: "user1"
        )
        #expect(mockWebSocket.sendMessageCalled == true)
        #expect(mockService.sendMessageCalled == false, "REST should not be called yet")

        // Simulate WebSocket send failure
        mockWebSocket.simulateSendFailure(receiverId: "user2", content: "Hello")

        // Allow the async recovery task to execute
        try await Task.sleep(nanoseconds: 300_000_000)

        // REST retry should have been attempted
        #expect(mockService.sendMessageCalled == true)
    }

    @Test func testSendFailureReconcilesTempMessageOnRESTSuccess() async throws {
        let (repository, _, mockWebSocket, messageStore) = makeRepository()
        try await connectAndWait(repository)

        let tempId = try await repository.sendMessage(
            receiverId: "user2",
            content: "Hello",
            token: "test-token",
            userId: "user1"
        )

        // Confirm temp message is pending
        let tempBefore = await messageStore.getTemporaryMessage(id: tempId)
        #expect(tempBefore != nil)

        // Simulate WebSocket send failure → REST succeeds (default mock behavior)
        mockWebSocket.simulateSendFailure(receiverId: "user2", content: "Hello")
        try await Task.sleep(nanoseconds: 300_000_000)

        // Temp message should be removed after successful reconciliation
        let tempAfter = await messageStore.getTemporaryMessage(id: tempId)
        #expect(tempAfter == nil)
    }

    // MARK: - Ambiguous Content Tests

    @Test func testSendFailureSkipsRecoveryWhenContentIsAmbiguous() async throws {
        let (repository, mockService, mockWebSocket, _) = makeRepository()
        try await connectAndWait(repository)

        // Enqueue two pending messages to the same receiver with identical content
        _ = try await repository.sendMessage(
            receiverId: "user2",
            content: "duplicate",
            token: "test-token",
            userId: "user1"
        )
        _ = try await repository.sendMessage(
            receiverId: "user2",
            content: "duplicate",
            token: "test-token",
            userId: "user1"
        )

        // Simulate failure for the shared content
        mockWebSocket.simulateSendFailure(receiverId: "user2", content: "duplicate")
        try await Task.sleep(nanoseconds: 300_000_000)

        // With two candidates, recovery is intentionally skipped to avoid choosing the wrong message
        #expect(mockService.sendMessageCalled == false)
    }

    // MARK: - REST Failure Tests

    @Test func testSendFailureMarksMessageAsFailedWhenRESTFails() async throws {
        let (repository, mockService, mockWebSocket, messageStore) = makeRepository()
        try await connectAndWait(repository)

        // Configure REST to always fail
        mockService.sendMessageBehavior = .failure(MockChatService.MockError.networkError)

        let tempId = try await repository.sendMessage(
            receiverId: "user2",
            content: "Hello",
            token: "test-token",
            userId: "user1"
        )

        // Simulate WebSocket send failure → REST also fails
        mockWebSocket.simulateSendFailure(receiverId: "user2", content: "Hello")
        try await Task.sleep(nanoseconds: 300_000_000)

        // The REST call was attempted
        #expect(mockService.sendMessageCalled == true)

        // Message in the store should now carry a .failed local status
        let messages = await messageStore.getMessages(for: "user2")
        let failedMessage = messages.first(where: { $0.id == tempId })
        #expect(failedMessage?.localStatus == .failed)
    }

    @Test func testSendFailurePendingMessageRemovedAfterRESTFailure() async throws {
        let (repository, mockService, mockWebSocket, messageStore) = makeRepository()
        try await connectAndWait(repository)

        mockService.sendMessageBehavior = .failure(MockChatService.MockError.networkError)

        let tempId = try await repository.sendMessage(
            receiverId: "user2",
            content: "Hello",
            token: "test-token",
            userId: "user1"
        )

        mockWebSocket.simulateSendFailure(receiverId: "user2", content: "Hello")
        try await Task.sleep(nanoseconds: 300_000_000)

        // Temp message record should be cleaned up even after failure
        let tempAfter = await messageStore.getTemporaryMessage(id: tempId)
        #expect(tempAfter == nil)
    }
}
