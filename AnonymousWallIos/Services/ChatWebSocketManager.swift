//
//  ChatWebSocketManager.swift
//  AnonymousWallIos
//
//  WebSocket manager for real-time chat functionality
//

import Foundation
import Combine

/// Protocol for WebSocket manager to enable testing
protocol ChatWebSocketManagerProtocol {
    var connectionState: WebSocketConnectionState { get }
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> { get }
    var messagePublisher: AnyPublisher<Message, Never> { get }
    var typingPublisher: AnyPublisher<String, Never> { get }
    var readReceiptPublisher: AnyPublisher<String, Never> { get }
    var unreadCountPublisher: AnyPublisher<Int, Never> { get }
    
    func connect(token: String, userId: String)
    func disconnect()
    func sendMessage(receiverId: String, content: String)
    func sendTypingIndicator(receiverId: String)
    func markAsRead(messageId: String)
}

/// WebSocket manager for real-time chat with automatic reconnection
@MainActor
class ChatWebSocketManager: ChatWebSocketManagerProtocol {
    
    // MARK: - Properties
    
    private let config = AppConfiguration.shared
    private var webSocketTask: URLSessionWebSocketTask?
    private var connectionStateSubject = CurrentValueSubject<WebSocketConnectionState, Never>(.disconnected)
    private var messageSubject = PassthroughSubject<Message, Never>()
    private var typingSubject = PassthroughSubject<String, Never>()
    private var readReceiptSubject = PassthroughSubject<String, Never>()
    private var unreadCountSubject = PassthroughSubject<Int, Never>()
    
    private var token: String?
    private var userId: String?
    private var reconnectAttempts = 0
    private var maxReconnectAttempts = 5
    private var heartbeatTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    
    // MARK: - Published Properties
    
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
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        // Disconnect must be called on main actor, but deinit is not isolated
        // The cleanup will happen when the actor is deallocated
        heartbeatTask?.cancel()
        receiveTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    // MARK: - Connection Management
    
    /// Connect to WebSocket server
    /// - Parameters:
    ///   - token: JWT authentication token
    ///   - userId: Current user ID
    func connect(token: String, userId: String) {
        self.token = token
        self.userId = userId
        
        // Only proceed if disconnected or reconnecting
        switch connectionState {
        case .disconnected, .reconnecting:
            break // Proceed with connection
        default:
            return // Already connecting or connected
        }
        
        connectionStateSubject.send(.connecting)
        reconnectAttempts = 0
        
        establishConnection()
    }
    
    /// Disconnect from WebSocket
    func disconnect() {
        heartbeatTask?.cancel()
        receiveTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionStateSubject.send(.disconnected)
    }
    
    // MARK: - Message Sending
    
    /// Send a chat message
    /// - Parameters:
    ///   - receiverId: Recipient user ID
    ///   - content: Message content
    func sendMessage(receiverId: String, content: String) {
        guard case .connected = connectionState else {
            Logger.chat.warning("Cannot send message: not connected")
            return
        }
        
        let message = WebSocketMessage(
            type: .message,
            receiverId: receiverId,
            content: content,
            messageId: nil,
            message: nil,
            senderId: nil,
            count: nil,
            userId: nil,
            timestamp: nil,
            error: nil
        )
        
        sendWebSocketMessage(message)
    }
    
    /// Send typing indicator
    /// - Parameter receiverId: Recipient user ID
    func sendTypingIndicator(receiverId: String) {
        guard case .connected = connectionState else { return }
        
        let message = WebSocketMessage(
            type: .typing,
            receiverId: receiverId,
            content: nil,
            messageId: nil,
            message: nil,
            senderId: nil,
            count: nil,
            userId: nil,
            timestamp: nil,
            error: nil
        )
        
        sendWebSocketMessage(message)
    }
    
    /// Mark message as read
    /// - Parameter messageId: Message ID to mark as read
    func markAsRead(messageId: String) {
        guard case .connected = connectionState else { return }
        
        let message = WebSocketMessage(
            type: .markRead,
            receiverId: nil,
            content: nil,
            messageId: messageId,
            message: nil,
            senderId: nil,
            count: nil,
            userId: nil,
            timestamp: nil,
            error: nil
        )
        
        sendWebSocketMessage(message)
    }
    
    // MARK: - Private Methods
    
    private func establishConnection() {
        guard let token = token else {
            connectionStateSubject.send(.failed(NetworkError.unauthorized))
            return
        }
        
        // Build WebSocket URL
        let wsScheme = config.environment == .development ? "ws" : "wss"
        let host = config.apiBaseURL.replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "https://", with: "")
        let wsURLString = "\(wsScheme)://\(host)/ws/chat"
        
        // Create WebSocket connection with authentication
        guard let url = URL(string: wsURLString) else {
                connectionStateSubject.send(.failed(NetworkError.invalidURL))
                return
            }

        let session = URLSession(configuration: .default)

        webSocketTask = session.webSocketTask(with: url, protocols: [token])
        webSocketTask?.resume()
        
        // Start receiving messages
        startReceiving()
        
        // Start heartbeat
        startHeartbeat()
        
        connectionStateSubject.send(.connected)
        Logger.chat.info("WebSocket connected")
    }
    
    private func startReceiving() {
        receiveTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { return }
                
                do {
                    let message = try await webSocketTask?.receive()
                    await self.handleReceivedMessage(message)
                } catch {
                    Logger.chat.error("WebSocket receive error: \(error)")
                    await self.handleConnectionFailure(error: error)
                    break
                }
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message?) async {
        guard let message = message else { return }
        
        switch message {
        case .string(let text):
            await parseWebSocketMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                await parseWebSocketMessage(text)
            }
        @unknown default:
            Logger.chat.warning("Unknown WebSocket message type")
        }
    }
    
    private func parseWebSocketMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let wsMessage = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            
            switch wsMessage.type {
            case .connected:
                Logger.chat.info("WebSocket connection confirmed")
                
            case .message:
                if let message = wsMessage.message {
                    messageSubject.send(message)
                }
                
            case .typing:
                if let senderId = wsMessage.senderId {
                    typingSubject.send(senderId)
                }
            case .markRead:
                // Backend notifies original sender that their message was read
                if let messageId = wsMessage.messageId {
                    readReceiptSubject.send(messageId)
                    Logger.chat.debug("Received markRead notification for message: \(messageId)")
                }
                
            case .readReceipt:
                if let messageId = wsMessage.messageId {
                    readReceiptSubject.send(messageId)
                }
                
            case .unreadCount:
                if let count = wsMessage.count {
                    unreadCountSubject.send(count)
                }
                
            case .error:
                if let error = wsMessage.error {
                    Logger.chat.error("WebSocket error: \(error)")
                }
                
            default:
                break
            }
        } catch {
            Logger.chat.error("Failed to decode WebSocket message: \(error)")
        }
    }
    
    private func sendWebSocketMessage(_ message: WebSocketMessage) {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            guard let text = String(data: data, encoding: .utf8) else { return }
            
            let urlMessage = URLSessionWebSocketTask.Message.string(text)
            
            Task {
                do {
                    try await webSocketTask.send(urlMessage)
                } catch {
                    Logger.chat.error("Failed to send WebSocket message: \(error)")
                }
            }
        } catch {
            Logger.chat.error("Failed to encode WebSocket message: \(error)")
        }
    }
    
    private func startHeartbeat() {
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
                guard let self = self,
                      let webSocketTask = await self.webSocketTask else {
                    break
                }
                
                // Send ping
                do {
                    try await webSocketTask.sendPing()
                } catch {
                    Logger.chat.warning("Heartbeat ping failed: \(error)")
                    await self.handleConnectionFailure(error: error)
                    break
                }
            }
        }
    }
    
    private func handleConnectionFailure(error: Error) {
        connectionStateSubject.send(.failed(error))
        
        // Attempt reconnection with exponential backoff
        if reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            connectionStateSubject.send(.reconnecting)
            
            let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Cap at 30 seconds
            Logger.chat.info("Reconnecting in \(delay) seconds (attempt \(reconnectAttempts))")
            
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await self?.establishConnection()
            }
        } else {
            Logger.chat.error("Max reconnection attempts reached")
            disconnect()
        }
    }
}

// MARK: - URLSessionWebSocketTask Extension

extension URLSessionWebSocketTask {
    func sendPing() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.sendPing { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
