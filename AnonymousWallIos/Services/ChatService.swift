//
//  ChatService.swift
//  AnonymousWallIos
//
//  Chat service for REST API operations
//

import Foundation

/// Chat service implementation for REST API
class ChatService: ChatServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = ChatService()
    
    private let networkClient: NetworkClientProtocol
    
    init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
    }
    
    // MARK: - ChatServiceProtocol
    
    func sendMessage(receiverId: String, content: String, token: String, userId: String) async throws -> Message {
        let request = SendMessageRequest(receiverId: receiverId, content: content)
        
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/messages")
            .setMethod(.POST)
            .setToken(token)
            .setBody(request)
            .build()
        
        return try await networkClient.performRequest(urlRequest)
    }
    
    func getMessageHistory(otherUserId: String, page: Int = 1, limit: Int = 50, token: String, userId: String) async throws -> MessageHistoryResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/messages/\(otherUserId)")
            .setMethod(.GET)
            .setToken(token)
            .addQueryItems(queryItems)
            .build()
        
        return try await networkClient.performRequest(urlRequest)
    }
    
    func getConversations(token: String, userId: String) async throws -> [Conversation] {
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/conversations")
            .setMethod(.GET)
            .setToken(token)
            .build()
        
        let response: ConversationsResponse = try await networkClient.performRequest(urlRequest)
        return response.conversations
    }
    
    func markMessageAsRead(messageId: String, token: String, userId: String) async throws {
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/messages/\(messageId)/read")
            .setMethod(.PUT)
            .setToken(token)
            .build()
        
        let _: MarkReadResponse = try await networkClient.performRequest(urlRequest)
    }
    
    func markConversationAsRead(otherUserId: String, token: String, userId: String) async throws {
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/conversations/\(otherUserId)/read")
            .setMethod(.PUT)
            .setToken(token)
            .build()
        
        let _: MarkReadResponse = try await networkClient.performRequest(urlRequest)
    }
}
