//
//  ChatWebSocketManagerTests.swift
//  AnonymousWallIosTests
//

import Testing
@testable import AnonymousWallIos
import Foundation

@MainActor
struct ChatWebSocketManagerTests {
    private let reconnectDelayVerificationNanos: UInt64 = 1_700_000_000

    @Test func testConnectStaysConnectingUntilServerConfirmation() async throws {
        let manager = ChatWebSocketManager()

        manager.connect(token: "access-token", userId: "user-1")

        #expect(manager.connectionState == .connecting)
        manager.disconnect()
    }

    @Test func testConnectedFrameTransitionsToConnected() async throws {
        let manager = ChatWebSocketManager()

        await manager.simulateIncomingTextMessageForTesting(#"{"type":"connected"}"#)

        #expect(manager.connectionState == .connected)
    }

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
        try await Task.sleep(nanoseconds: reconnectDelayVerificationNanos)
        #expect(manager.connectionState == .disconnected)
    }
}
