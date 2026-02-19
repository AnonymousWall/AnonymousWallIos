//
//  MockMarketplaceService.swift
//  AnonymousWallIos
//
//  Mock implementation of MarketplaceServiceProtocol for unit testing
//

import Foundation

class MockMarketplaceService: MarketplaceServiceProtocol {

    // MARK: - Configuration

    enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }

    // MARK: - State Tracking

    var fetchItemsCalled = false
    var getItemCalled = false
    var createItemCalled = false
    var updateItemCalled = false
    var hideItemCalled = false
    var unhideItemCalled = false
    var addCommentCalled = false
    var getCommentsCalled = false
    var hideCommentCalled = false
    var unhideCommentCalled = false

    // MARK: - Configurable Behavior

    var fetchItemsBehavior: MockBehavior = .success
    var getItemBehavior: MockBehavior = .success
    var createItemBehavior: MockBehavior = .success
    var updateItemBehavior: MockBehavior = .success
    var hideItemBehavior: MockBehavior = .success
    var unhideItemBehavior: MockBehavior = .success
    var addCommentBehavior: MockBehavior = .success
    var getCommentsBehavior: MockBehavior = .success
    var hideCommentBehavior: MockBehavior = .success
    var unhideCommentBehavior: MockBehavior = .success

    // MARK: - Mock Data

    var mockItems: [MarketplaceItem] = []
    var mockItem: MarketplaceItem?
    var mockComments: [Comment] = []
    var mockHideResponse: HidePostResponse?

    // MARK: - Initialization

    init() {}

    // MARK: - Marketplace Operations

    func fetchItems(
        token: String,
        userId: String,
        wall: WallType,
        page: Int,
        limit: Int,
        sortBy: MarketplaceSortOrder,
        sold: Bool?
    ) async throws -> MarketplaceListResponse {
        fetchItemsCalled = true
        switch fetchItemsBehavior {
        case .success:
            var items = mockItems
            if let sold {
                items = items.filter { $0.sold == sold }
            }
            return MarketplaceListResponse(
                data: items,
                pagination: PostListResponse.Pagination(
                    page: page, limit: limit, total: items.count,
                    totalPages: items.isEmpty ? 0 : (items.count + limit - 1) / limit
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return MarketplaceListResponse(
                data: [],
                pagination: PostListResponse.Pagination(page: page, limit: limit, total: 0, totalPages: 0)
            )
        }
    }

    func getItem(itemId: String, token: String, userId: String) async throws -> MarketplaceItem {
        getItemCalled = true
        switch getItemBehavior {
        case .success:
            return mockItem ?? MarketplaceItem(
                id: itemId,
                title: "Mock Item",
                price: 9.99,
                description: nil,
                category: nil,
                condition: nil,
                contactInfo: nil,
                sold: false,
                wall: "CAMPUS",
                comments: 0,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: false),
                createdAt: "2026-02-19T00:00:00Z",
                updatedAt: "2026-02-19T00:00:00Z"
            )
        case .failure(let error): throw error
        case .emptyState:
            return MarketplaceItem(
                id: "", title: "", price: 0, description: nil, category: nil, condition: nil,
                contactInfo: nil, sold: false, wall: "", comments: 0,
                author: Post.Author(id: "", profileName: "", isAnonymous: false),
                createdAt: "", updatedAt: ""
            )
        }
    }

    func createItem(
        title: String,
        price: Double,
        description: String?,
        category: String?,
        condition: String?,
        contactInfo: String?,
        wall: WallType,
        token: String,
        userId: String
    ) async throws -> MarketplaceItem {
        createItemCalled = true
        switch createItemBehavior {
        case .success:
            let item = MarketplaceItem(
                id: "new-item-\(mockItems.count)",
                title: title,
                price: price,
                description: description,
                category: category,
                condition: condition,
                contactInfo: contactInfo,
                sold: false,
                wall: wall.rawValue,
                comments: 0,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: false),
                createdAt: "2026-02-19T00:00:00Z",
                updatedAt: "2026-02-19T00:00:00Z"
            )
            mockItems.append(item)
            return item
        case .failure(let error): throw error
        case .emptyState:
            return MarketplaceItem(
                id: "", title: "", price: 0, description: nil, category: nil, condition: nil,
                contactInfo: nil, sold: false, wall: "", comments: 0,
                author: Post.Author(id: "", profileName: "", isAnonymous: false),
                createdAt: "", updatedAt: ""
            )
        }
    }

    func updateItem(
        itemId: String,
        request: UpdateMarketplaceRequest,
        token: String,
        userId: String
    ) async throws -> MarketplaceItem {
        updateItemCalled = true
        switch updateItemBehavior {
        case .success:
            return mockItem ?? MarketplaceItem(
                id: itemId, title: request.title ?? "Updated", price: request.price ?? 0,
                description: request.description, category: request.category,
                condition: request.condition, contactInfo: request.contactInfo,
                sold: request.sold ?? false, wall: "CAMPUS", comments: 0,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: false),
                createdAt: "2026-02-19T00:00:00Z", updatedAt: "2026-02-19T00:00:00Z"
            )
        case .failure(let error): throw error
        case .emptyState:
            return MarketplaceItem(
                id: "", title: "", price: 0, description: nil, category: nil, condition: nil,
                contactInfo: nil, sold: false, wall: "", comments: 0,
                author: Post.Author(id: "", profileName: "", isAnonymous: false),
                createdAt: "", updatedAt: ""
            )
        }
    }

    func hideItem(itemId: String, token: String, userId: String) async throws -> HidePostResponse {
        hideItemCalled = true
        switch hideItemBehavior {
        case .success: return mockHideResponse ?? HidePostResponse(message: "Item hidden successfully")
        case .failure(let error): throw error
        case .emptyState: return HidePostResponse(message: "")
        }
    }

    func unhideItem(itemId: String, token: String, userId: String) async throws -> HidePostResponse {
        unhideItemCalled = true
        switch unhideItemBehavior {
        case .success: return mockHideResponse ?? HidePostResponse(message: "Item unhidden successfully")
        case .failure(let error): throw error
        case .emptyState: return HidePostResponse(message: "")
        }
    }

    // MARK: - Comment Operations

    func addComment(itemId: String, text: String, token: String, userId: String) async throws -> Comment {
        addCommentCalled = true
        switch addCommentBehavior {
        case .success:
            let comment = Comment(
                id: "new-comment-\(mockComments.count)",
                postId: itemId,
                parentType: "MARKETPLACE",
                text: text,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: true),
                createdAt: "2026-02-19T00:00:00Z"
            )
            mockComments.append(comment)
            return comment
        case .failure(let error): throw error
        case .emptyState:
            return Comment(id: "", postId: "", parentType: nil, text: "", author: Post.Author(id: "", profileName: "", isAnonymous: false), createdAt: "")
        }
    }

    func getComments(
        itemId: String,
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse {
        getCommentsCalled = true
        switch getCommentsBehavior {
        case .success:
            let filtered = mockComments.filter { $0.postId == itemId }
            return CommentListResponse(
                data: filtered,
                pagination: PostListResponse.Pagination(
                    page: page, limit: limit, total: filtered.count,
                    totalPages: filtered.isEmpty ? 0 : (filtered.count + limit - 1) / limit
                )
            )
        case .failure(let error): throw error
        case .emptyState:
            return CommentListResponse(data: [], pagination: PostListResponse.Pagination(page: page, limit: limit, total: 0, totalPages: 0))
        }
    }

    func hideComment(itemId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        hideCommentCalled = true
        switch hideCommentBehavior {
        case .success: return mockHideResponse ?? HidePostResponse(message: "Comment hidden successfully")
        case .failure(let error): throw error
        case .emptyState: return HidePostResponse(message: "")
        }
    }

    func unhideComment(itemId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        unhideCommentCalled = true
        switch unhideCommentBehavior {
        case .success: return mockHideResponse ?? HidePostResponse(message: "Comment unhidden successfully")
        case .failure(let error): throw error
        case .emptyState: return HidePostResponse(message: "")
        }
    }

    // MARK: - Helper Methods

    func resetCallTracking() {
        fetchItemsCalled = false
        getItemCalled = false
        createItemCalled = false
        updateItemCalled = false
        hideItemCalled = false
        unhideItemCalled = false
        addCommentCalled = false
        getCommentsCalled = false
        hideCommentCalled = false
        unhideCommentCalled = false
    }
}
