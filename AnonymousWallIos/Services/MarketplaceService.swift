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
    private let mediaService: MediaServiceProtocol

    private init(mediaService: MediaServiceProtocol = MediaService.shared) {
        self.mediaService = mediaService
    }

    // MARK: - Marketplace Operations

    func fetchItems(
        token: String,
        userId: String,
        wall: WallType = .campus,
        page: Int = 1,
        limit: Int = 20,
        sortBy: MarketplaceSortOrder = .newest,
        category: MarketplaceCategory? = nil
    ) async throws -> MarketplaceListResponse {
        var queryItems = [
            URLQueryItem(name: "wall", value: wall.rawValue),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy.rawValue)
        ]
        if let category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
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
        images: [UIImage] = [],
        token: String,
        userId: String
    ) async throws -> MarketplaceItem {
        let objectNames = try await mediaService.uploadImages(images, folder: "marketplace", token: token)

        struct CreateItemBody: Encodable {
            let title: String
            let price: Double
            let description: String?
            let category: String?
            let condition: String?
            let wall: String
            let imageObjectNames: [String]
        }

        let body = CreateItemBody(
            title: title,
            price: price,
            description: description,
            category: category,
            condition: condition,
            wall: wall.rawValue,
            imageObjectNames: objectNames
        )

        let request = try APIRequestBuilder()
            .setPath("/marketplace")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .setBody(body)
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
