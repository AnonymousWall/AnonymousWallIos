//
//  ChatWebSocketManagerTests.swift
//  AnonymousWallIosTests
//

import Testing
@testable import AnonymousWallIos
import Foundation

@MainActor
struct ChatWebSocketManagerTests {

    @Test func testExpiredTokenHandshakeTransitionsToDisconnected() async throws {
        let manager = ChatWebSocketManager()

        manager.simulateConnectionFailureForTesting(URLError(.badServerResponse))

        #expect(manager.connectionState == .disconnected)
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(manager.connectionState == .disconnected)
    }

    @Test func testTransientConnectionFailureEntersReconnectingState() async throws {
        let manager = ChatWebSocketManager()

        manager.simulateConnectionFailureForTesting(URLError(.timedOut))

        #expect(manager.connectionState == .reconnecting)
        manager.disconnect()
        #expect(manager.connectionState == .disconnected)
    }
}
