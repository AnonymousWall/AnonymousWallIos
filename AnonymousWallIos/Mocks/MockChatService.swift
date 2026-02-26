//
//  MockChatService.swift
//  AnonymousWallIos
//
//  Mock implementation of ChatServiceProtocol for unit testing
//

import Foundation

/// Mock ChatService for testing with configurable responses
class MockChatService: ChatServiceProtocol {
    
    // MARK: - Configuration
    
    enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }
    
    enum MockError: Error, LocalizedError {
        case unauthorized
        case networkError
        case serverError
        case messageNotFound
        case userNotFound
        
        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Unauthorized access"
            case .networkError:
                return "Network error"
            case .serverError:
                return "Server error"
            case .messageNotFound:
                return "Message not found"
            case .userNotFound:
                return "User not found"
            }
        }
    }
    
    // MARK: - State Tracking
    
    var sendMessageCalled = false
    var sendImageMessageCalled = false
    var uploadChatImageCalled = false
    var getMessageHistoryCalled = false
    var getConversationsCalled = false
    var markMessageAsReadCalled = false
    var markConversationAsReadCalled = false
    
    // MARK: - Configurable Behavior
    
    var sendMessageBehavior: MockBehavior = .success
    var sendImageMessageBehavior: MockBehavior = .success
    var uploadChatImageBehavior: MockBehavior = .success
    var getMessageHistoryBehavior: MockBehavior = .success
    var getConversationsBehavior: MockBehavior = .success
    var markMessageAsReadBehavior: MockBehavior = .success
    var markConversationAsReadBehavior: MockBehavior = .success
    
    // MARK: - Configurable State
    
    var mockMessages: [Message] = []
    var mockConversations: [Conversation] = []
    var mockImageUrl: String = "https://example.com/mock-image.jpg"
    
    // MARK: - ChatServiceProtocol
    
    func sendMessage(receiverId: String, content: String, token: String, userId: String) async throws -> Message {
        sendMessageCalled = true
        
        switch sendMessageBehavior {
        case .success:
            let message = Message(
                id: UUID().uuidString,
                senderId: userId,
                receiverId: receiverId,
                content: content,
                readStatus: false,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            mockMessages.append(message)
            return message
            
        case .failure(let error):
            throw error
            
        case .emptyState:
            throw MockError.serverError
        }
    }
    
    func sendImageMessage(receiverId: String, imageUrl: String, token: String, userId: String) async throws -> Message {
        sendImageMessageCalled = true
        
        switch sendImageMessageBehavior {
        case .success:
            let message = Message(
                id: UUID().uuidString,
                senderId: "mockUserId",
                receiverId: receiverId,
                content: "",
                imageUrl: imageUrl,
                readStatus: false,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            mockMessages.append(message)
            return message
            
        case .failure(let error):
            throw error
            
        case .emptyState:
            throw MockError.serverError
        }
    }
    
    func uploadChatImage(_ jpeg: Data, token: String, userId: String) async throws -> String {
        uploadChatImageCalled = true
        
        switch uploadChatImageBehavior {
        case .success:
            return mockImageUrl
            
        case .failure(let error):
            throw error
            
        case .emptyState:
            throw MockError.serverError
        }
    }
    
    func getMessageHistory(otherUserId: String, page: Int, limit: Int, token: String, userId: String) async throws -> MessageHistoryResponse {
        getMessageHistoryCalled = true
        
        switch getMessageHistoryBehavior {
        case .success:
            return MessageHistoryResponse(
                messages: mockMessages,
                pagination: MessagePagination(
                    page: page,
                    limit: limit,
                    total: mockMessages.count,
                    totalPages: 1
                )
            )
            
        case .failure(let error):
            throw error
            
        case .emptyState:
            return MessageHistoryResponse(
                messages: [],
                pagination: MessagePagination(
                    page: page,
                    limit: limit,
                    total: 0,
                    totalPages: 0
                )
            )
        }
    }
    
    func getConversations(token: String, userId: String) async throws -> [Conversation] {
        getConversationsCalled = true
        
        switch getConversationsBehavior {
        case .success:
            return mockConversations
            
        case .failure(let error):
            throw error
            
        case .emptyState:
            return []
        }
    }
    
    func markMessageAsRead(messageId: String, token: String, userId: String) async throws {
        markMessageAsReadCalled = true
        
        switch markMessageAsReadBehavior {
        case .success:
            return
            
        case .failure(let error):
            throw error
            
        case .emptyState:
            return
        }
    }
    
    func markConversationAsRead(otherUserId: String, token: String, userId: String) async throws {
        markConversationAsReadCalled = true
        
        switch markConversationAsReadBehavior {
        case .success:
            return
            
        case .failure(let error):
            throw error
            
        case .emptyState:
            return
        }
    }
}
