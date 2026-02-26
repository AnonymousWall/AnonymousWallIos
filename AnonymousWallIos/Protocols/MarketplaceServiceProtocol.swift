//
//  MarketplaceServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for marketplace service operations
//

import Foundation
import UIKit

protocol MarketplaceServiceProtocol {
    // MARK: - Marketplace Operations

    func fetchItems(
        token: String,
        userId: String,
        wall: WallType,
        page: Int,
        limit: Int,
        sortBy: MarketplaceSortOrder
    ) async throws -> MarketplaceListResponse

    func getItem(
        itemId: String,
        token: String,
        userId: String
    ) async throws -> MarketplaceItem

    func createItem(
        title: String,
        price: Double,
        description: String?,
        category: String?,
        condition: String?,
        wall: WallType,
        images: [UIImage],
        token: String,
        userId: String
    ) async throws -> MarketplaceItem

    func updateItem(
        itemId: String,
        request: UpdateMarketplaceRequest,
        token: String,
        userId: String
    ) async throws -> MarketplaceItem

    func hideItem(itemId: String, token: String, userId: String) async throws -> HidePostResponse
    func unhideItem(itemId: String, token: String, userId: String) async throws -> HidePostResponse

    // MARK: - Comment Operations

    func addComment(itemId: String, text: String, token: String, userId: String) async throws -> Comment

    func getComments(
        itemId: String,
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse

    func hideComment(itemId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse
    func unhideComment(itemId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse
}
