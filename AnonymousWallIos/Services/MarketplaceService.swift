//
//  MarketplaceService.swift
//  AnonymousWallIos
//
//  Service for marketplace-related API calls
//

import Foundation
import UIKit

class MarketplaceService: MarketplaceServiceProtocol {
    static let shared: MarketplaceServiceProtocol = MarketplaceService()

    private let config = AppConfiguration.shared
    private let networkClient = NetworkClient.shared

    private init() {}

    // MARK: - Marketplace Operations

    func fetchItems(
        token: String,
        userId: String,
        wall: WallType = .campus,
        page: Int = 1,
        limit: Int = 20,
        sortBy: MarketplaceSortOrder = .newest
    ) async throws -> MarketplaceListResponse {
        let queryItems = [
            URLQueryItem(name: "wall", value: wall.rawValue),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy.rawValue)
        ]

        let request = try APIRequestBuilder()
            .setPath("/marketplace")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func getItem(
        itemId: String,
        token: String,
        userId: String
    ) async throws -> MarketplaceItem {
        let request = try APIRequestBuilder()
            .setPath("/marketplace/\(itemId)")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func createItem(
        title: String,
        price: Double,
        description: String?,
        category: String?,
        condition: String?,
        wall: WallType = .campus,
        images: [UIImage] = [],
        token: String,
        userId: String
    ) async throws -> MarketplaceItem {
        guard let url = URL(string: config.fullAPIBaseURL + "/marketplace") else {
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
        body.appendFormField(name: "title", value: title, boundary: boundary)
        body.appendFormField(name: "price", value: String(price), boundary: boundary)
        if let description, !description.isEmpty {
            body.appendFormField(name: "description", value: description, boundary: boundary)
        }
        if let category, !category.isEmpty {
            body.appendFormField(name: "category", value: category, boundary: boundary)
        }
        if let condition, !condition.isEmpty {
            body.appendFormField(name: "condition", value: condition, boundary: boundary)
        }
        body.appendFormField(name: "wall", value: wall.rawValue, boundary: boundary)

        for (index, image) in images.prefix(5).enumerated() {
            let resized = image.resized(maxDimension: 1024)
            if let jpeg = resized.jpegData(compressionQuality: 0.6) {
                body.appendFileField(
                    name: "images",
                    filename: "image\(index).jpg",
                    mimeType: "image/jpeg",
                    data: jpeg,
                    boundary: boundary
                )
            }
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.waitsForConnectivity = true
        let session = URLSession(configuration: sessionConfig)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 { throw NetworkError.unauthorized }
            if httpResponse.statusCode == 403 { throw NetworkError.forbidden }
            let message = String(data: data, encoding: .utf8) ?? "Server error"
            throw NetworkError.serverError(message)
        }

        return try JSONDecoder().decode(MarketplaceItem.self, from: data)
    }

    func updateItem(
        itemId: String,
        request updateRequest: UpdateMarketplaceRequest,
        token: String,
        userId: String
    ) async throws -> MarketplaceItem {
        let request = try APIRequestBuilder()
            .setPath("/marketplace/\(itemId)")
            .setMethod(.PUT)
            .setBody(updateRequest)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func hideItem(
        itemId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/marketplace/\(itemId)/hide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func unhideItem(
        itemId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/marketplace/\(itemId)/unhide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    // MARK: - Comment Operations

    func addComment(
        itemId: String,
        text: String,
        token: String,
        userId: String
    ) async throws -> Comment {
        let body = CreateCommentRequest(text: text)

        let request = try APIRequestBuilder()
            .setPath("/marketplace/\(itemId)/comments")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func getComments(
        itemId: String,
        token: String,
        userId: String,
        page: Int = 1,
        limit: Int = 20,
        sort: SortOrder = .newest
    ) async throws -> CommentListResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: sort.rawValue)
        ]

        let request = try APIRequestBuilder()
            .setPath("/marketplace/\(itemId)/comments")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func hideComment(
        itemId: String,
        commentId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/marketplace/\(itemId)/comments/\(commentId)/hide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func unhideComment(
        itemId: String,
        commentId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        let request = try APIRequestBuilder()
            .setPath("/marketplace/\(itemId)/comments/\(commentId)/unhide")
            .setMethod(.PATCH)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }
}
