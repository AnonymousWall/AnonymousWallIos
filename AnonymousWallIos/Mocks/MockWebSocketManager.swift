//
//  MockWebSocketManager.swift
//  AnonymousWallIos
//
//  Mock implementation of ChatWebSocketManagerProtocol for unit testing
//

import Foundation
import Combine

/// Mock WebSocket manager for testing
@MainActor
class MockWebSocketManager: ChatWebSocketManagerProtocol {
    
    // MARK: - Published Properties
    
    private var connectionStateSubject = CurrentValueSubject<WebSocketConnectionState, Never>(.disconnected)
    private var messageSubject = PassthroughSubject<Message, Never>()
    private var typingSubject = PassthroughSubject<String, Never>()
    private var readReceiptSubject = PassthroughSubject<String, Never>()
    private var unreadCountSubject = PassthroughSubject<Int, Never>()
    
    var connectionState: WebSocketConnectionState {
        connectionStateSubject.value
    }
    
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    var messagePublisher: AnyPublisher<Message, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var typingPublisher: AnyPublisher<String, Never> {
        typingSubject.eraseToAnyPublisher()
    }
    
    var readReceiptPublisher: AnyPublisher<String, Never> {
        readReceiptSubject.eraseToAnyPublisher()
    }
    
    var unreadCountPublisher: AnyPublisher<Int, Never> {
        unreadCountSubject.eraseToAnyPublisher()
    }
    
    // MARK: - State Tracking
    
    var connectCalled = false
    var disconnectCalled = false
    var sendMessageCalled = false
    var sendTypingIndicatorCalled = false
    var markAsReadCalled = false
    
    var lastSentMessage: (receiverId: String, content: String)?
    var lastTypingReceiverId: String?
    var lastMarkReadMessageId: String?
    
    // MARK: - Simulation Control
    
    var shouldAutoConnect = true
    var simulateConnectionFailure = false
    
    // MARK: - ChatWebSocketManagerProtocol
    
    func connect(token: String, userId: String) {
        connectCalled = true
        
        if simulateConnectionFailure {
            connectionStateSubject.send(.failed(NetworkError.serverError(500, "Connection failed")))
        } else if shouldAutoConnect {
            connectionStateSubject.send(.connecting)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.connectionStateSubject.send(.connected)
            }
        }
    }
    
    func disconnect() {
        disconnectCalled = true
        connectionStateSubject.send(.disconnected)
    }
    
    func sendMessage(receiverId: String, content: String) {
        sendMessageCalled = true
        lastSentMessage = (receiverId, content)
    }
    
    func sendTypingIndicator(receiverId: String) {
        sendTypingIndicatorCalled = true
        lastTypingReceiverId = receiverId
    }
    
    func markAsRead(messageId: String) {
        markAsReadCalled = true
        lastMarkReadMessageId = messageId
    }
    
    // MARK: - Test Helpers
    
    /// Simulate receiving a message
    func simulateReceiveMessage(_ message: Message) {
        messageSubject.send(message)
    }
    
    /// Simulate receiving a typing indicator
    func simulateTyping(from senderId: String) {
        typingSubject.send(senderId)
    }
    
    /// Simulate receiving a read receipt
    func simulateReadReceipt(for messageId: String) {
        readReceiptSubject.send(messageId)
    }
    
    /// Simulate receiving unread count update
    func simulateUnreadCount(_ count: Int) {
        unreadCountSubject.send(count)
    }
    
    /// Simulate reconnection
    func simulateReconnect() {
        connectionStateSubject.send(.reconnecting)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.connectionStateSubject.send(.connected)
        }
    }
    
    /// Reset all tracking state
    func reset() {
        connectCalled = false
        disconnectCalled = false
        sendMessageCalled = false
        sendTypingIndicatorCalled = false
        markAsReadCalled = false
        lastSentMessage = nil
        lastTypingReceiverId = nil
        lastMarkReadMessageId = nil
        connectionStateSubject.send(.disconnected)
    }
}
