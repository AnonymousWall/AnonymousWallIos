//
//  ChatRepositoryTokenRefreshTests.swift
//  AnonymousWallIosTests
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct ChatRepositoryTokenRefreshTests {

    @Test func testTokenRefreshNotificationUpdatesWebSocketManagerToken() async throws {
        let mockWebSocket = MockWebSocketManager()
        let repository = ChatRepository(
            chatService: MockChatService(),
            webSocketManager: mockWebSocket,
            messageStore: MessageStore()
        )
        _ = repository

        NotificationCenter.default.post(
            name: .tokenRefreshed,
            object: nil,
            userInfo: ["token": "new-access-token"]
        )

        #expect(mockWebSocket.updateTokenCalled == true)
        #expect(mockWebSocket.updatedToken == "new-access-token")
    }

    @Test func testTokenRefreshReconnectsDeadWebSocketWhenConnectionShouldBeMaintained() async throws {
        let mockWebSocket = MockWebSocketManager()
        let repository = ChatRepository(
            chatService: MockChatService(),
            webSocketManager: mockWebSocket,
            messageStore: MessageStore()
        )

        repository.connect(token: "expired-token", userId: "user-1")
        #expect(mockWebSocket.connectCallCount == 1)

        mockWebSocket.disconnect()
        repository.updateCachedToken("fresh-token")

        #expect(mockWebSocket.connectCallCount == 2)
        #expect(mockWebSocket.lastConnectedCredentials?.token == "fresh-token")
        #expect(mockWebSocket.lastConnectedCredentials?.userId == "user-1")
    }

    @Test func testTokenRefreshDoesNotReconnectAfterManualDisconnect() async throws {
        let mockWebSocket = MockWebSocketManager()
        let repository = ChatRepository(
            chatService: MockChatService(),
            webSocketManager: mockWebSocket,
            messageStore: MessageStore()
        )

        repository.connect(token: "expired-token", userId: "user-1")
        repository.disconnect()
        repository.updateCachedToken("fresh-token")

        #expect(mockWebSocket.connectCallCount == 1)
        #expect(mockWebSocket.updatedToken == "fresh-token")
    }

    @Test func testUpdateCachedTokenUpdatesWebSocketManagerImmediately() async throws {
        let mockWebSocket = MockWebSocketManager()
        let repository = ChatRepository(
            chatService: MockChatService(),
            webSocketManager: mockWebSocket,
            messageStore: MessageStore()
        )

        repository.updateCachedToken("fresh-token")

        #expect(mockWebSocket.updateTokenCalled == true)
        #expect(mockWebSocket.updatedToken == "fresh-token")
    }
}
