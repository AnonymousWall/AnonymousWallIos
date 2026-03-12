//
//  ChatAPIService.swift
//  AnonymousWallIos
//
//  Chat service for REST API operations
//

import Foundation
import UIKit

/// Chat service implementation for REST API
class ChatAPIService: ChatAPIServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = ChatAPIService()
    
    private let networkClient: NetworkClientProtocol
    private let config = AppConfiguration.shared
    
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
        
        return try await networkClient.performRequest(urlRequest, retryPolicy: .default)
    }
    
    func sendImageMessage(receiverId: String, imageUrl: String, token: String, userId: String) async throws -> Message {
        let request = SendMessageRequest(receiverId: receiverId, content: "", imageUrl: imageUrl)
        
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/messages")
            .setMethod(.POST)
            .setToken(token)
            .setBody(request)
            .build()
        
        return try await networkClient.performRequest(urlRequest, retryPolicy: .default)
    }
    
    func uploadChatImage(_ jpeg: Data, token: String, userId: String) async throws -> String {
        guard let url = URL(string: config.fullAPIBaseURL + "/chat/images") else {
            throw NetworkError.invalidURL
        }
        
        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(userId, forHTTPHeaderField: "X-User-Id")
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60
        urlRequest.assumesHTTP3Capable = false
        
        var body = Data()
        body.appendFileField(
            name: "image",
            filename: "image.jpg",
            mimeType: "image/jpeg",
            data: jpeg,
            boundary: boundary
        )
        guard let closingBoundary = "--\(boundary)--\r\n".data(using: .utf8) else {
            throw NetworkError.serverError("Failed to build multipart body")
        }
        body.append(closingBoundary)
        urlRequest.httpBody = body
        
        let data = try await NetworkClient.shared.performMultipartRequest(urlRequest)
        struct UploadResponse: Decodable { let url: String }
        return try JSONDecoder().decode(UploadResponse.self, from: data).url
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
        
        return try await networkClient.performRequest(urlRequest, retryPolicy: .default)
    }
    
    func getConversations(token: String, userId: String) async throws -> [Conversation] {
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/conversations")
            .setMethod(.GET)
            .setToken(token)
            .build()
        
        let response: ConversationsResponse = try await networkClient.performRequest(urlRequest, retryPolicy: .default)
        return response.conversations
    }
    
    func markMessageAsRead(messageId: String, token: String, userId: String) async throws {
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/messages/\(messageId)/read")
            .setMethod(.PUT)
            .setToken(token)
            .build()
        
        let _: MarkReadResponse = try await networkClient.performRequest(urlRequest, retryPolicy: .default)
    }
    
    func markConversationAsRead(otherUserId: String, token: String, userId: String) async throws {
        let urlRequest = try APIRequestBuilder()
            .setPath("/chat/conversations/\(otherUserId)/read")
            .setMethod(.PUT)
            .setToken(token)
            .build()
        
        let _: MarkReadResponse = try await networkClient.performRequest(urlRequest, retryPolicy: .default)
    }
}
