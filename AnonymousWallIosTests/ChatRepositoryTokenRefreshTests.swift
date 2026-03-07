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

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(mockWebSocket.updateTokenCalled == true)
        #expect(mockWebSocket.updatedToken == "new-access-token")
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
