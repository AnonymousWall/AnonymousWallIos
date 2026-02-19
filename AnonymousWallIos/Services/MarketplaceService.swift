//
//  MarketplaceService.swift
//  AnonymousWallIos
//
//  Service for marketplace-related API calls
//

import Foundation

class MarketplaceService: MarketplaceServiceProtocol {
    static let shared: MarketplaceServiceProtocol = MarketplaceService()

    private let networkClient = NetworkClient.shared

    private init() {}

    // MARK: - Marketplace Operations

    func fetchItems(
        token: String,
        userId: String,
        wall: WallType = .campus,
        page: Int = 1,
        limit: Int = 20,
        sortBy: MarketplaceSortOrder = .newest,
        sold: Bool? = nil
    ) async throws -> MarketplaceListResponse {
        var queryItems = [
            URLQueryItem(name: "wall", value: wall.rawValue),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy.rawValue)
        ]

        if let sold {
            queryItems.append(URLQueryItem(name: "sold", value: sold ? "true" : "false"))
        }

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
        token: String,
        userId: String
    ) async throws -> MarketplaceItem {
        let body = CreateMarketplaceRequest(
            title: title,
            price: price,
            description: description,
            category: category,
            condition: condition,
            wall: wall.rawValue
        )

        let request = try APIRequestBuilder()
            .setPath("/marketplace")
            .setMethod(.POST)
            .setBody(body)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
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
