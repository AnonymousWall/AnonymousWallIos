//
//  MockUserService.swift
//  AnonymousWallIos
//
//  Mock implementation of UserServiceProtocol for unit testing
//  Provides configurable stub responses for success, failure, and empty states
//

import Foundation

/// Mock UserService for testing with configurable responses
class MockUserService: UserServiceProtocol {
    
    // MARK: - Configuration
    
    /// Configuration for mock behavior
    enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }
    
    /// Default error for failure scenarios
    enum MockError: Error, LocalizedError {
        case unauthorized
        case networkError
        case serverError
        case notFound
        
        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Unauthorized"
            case .networkError:
                return "Network error"
            case .serverError:
                return "Server error"
            case .notFound:
                return "Not found"
            }
        }
    }
    
    // MARK: - State Tracking
    
    var updateProfileNameCalled = false
    var getUserCommentsCalled = false
    var getUserPostsCalled = false
    var getUserInternshipsCalled = false
    var getUserMarketplacesCalled = false
    
    // MARK: - Configurable Behavior
    
    var updateProfileNameBehavior: MockBehavior = .success
    var getUserCommentsBehavior: MockBehavior = .success
    var getUserPostsBehavior: MockBehavior = .success
    var getUserInternshipsBehavior: MockBehavior = .success
    var getUserMarketplacesBehavior: MockBehavior = .success
    
    // MARK: - Configurable Responses
    
    var mockUser: User?
    var mockComments: [Comment] = []
    var mockPosts: [Post] = []
    var mockInternships: [Internship] = []
    var mockMarketplaceItems: [MarketplaceItem] = []
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Protocol Methods
    
    func updateProfileName(profileName: String, token: String, userId: String) async throws -> User {
        updateProfileNameCalled = true
        
        switch updateProfileNameBehavior {
        case .success:
            return mockUser ?? User(
                id: userId,
                email: "test@example.com",
                profileName: profileName,
                isVerified: true,
                passwordSet: true,
                createdAt: "2026-02-09T00:00:00Z"
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return User(
                id: "",
                email: "",
                profileName: "",
                isVerified: false,
                passwordSet: false,
                createdAt: ""
            )
        }
    }
    
    func getUserComments(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse {
        getUserCommentsCalled = true
        
        switch getUserCommentsBehavior {
        case .success:
            let totalPages = mockComments.isEmpty ? 1 : (mockComments.count + limit - 1) / limit
            return CommentListResponse(
                data: mockComments,
                pagination: PostListResponse.Pagination(
                    page: page,
                    limit: limit,
                    total: mockComments.count,
                    totalPages: totalPages
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return CommentListResponse(
                data: [],
                pagination: PostListResponse.Pagination(
                    page: 1,
                    limit: limit,
                    total: 0,
                    totalPages: 1
                )
            )
        }
    }
    
    func getUserPosts(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> PostListResponse {
        getUserPostsCalled = true
        
        switch getUserPostsBehavior {
        case .success:
            let totalPages = mockPosts.isEmpty ? 1 : (mockPosts.count + limit - 1) / limit
            return PostListResponse(
                data: mockPosts,
                pagination: PostListResponse.Pagination(
                    page: page,
                    limit: limit,
                    total: mockPosts.count,
                    totalPages: totalPages
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return PostListResponse(
                data: [],
                pagination: PostListResponse.Pagination(
                    page: 1,
                    limit: limit,
                    total: 0,
                    totalPages: 1
                )
            )
        }
    }
    
    func getUserInternships(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> InternshipListResponse {
        getUserInternshipsCalled = true
        
        switch getUserInternshipsBehavior {
        case .success:
            let totalPages = mockInternships.isEmpty ? 1 : (mockInternships.count + limit - 1) / limit
            return InternshipListResponse(
                data: mockInternships,
                pagination: PostListResponse.Pagination(
                    page: page,
                    limit: limit,
                    total: mockInternships.count,
                    totalPages: totalPages
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return InternshipListResponse(
                data: [],
                pagination: PostListResponse.Pagination(
                    page: 1,
                    limit: limit,
                    total: 0,
                    totalPages: 1
                )
            )
        }
    }
    
    func getUserMarketplaces(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> MarketplaceListResponse {
        getUserMarketplacesCalled = true
        
        switch getUserMarketplacesBehavior {
        case .success:
            let totalPages = mockMarketplaceItems.isEmpty ? 1 : (mockMarketplaceItems.count + limit - 1) / limit
            return MarketplaceListResponse(
                data: mockMarketplaceItems,
                pagination: PostListResponse.Pagination(
                    page: page,
                    limit: limit,
                    total: mockMarketplaceItems.count,
                    totalPages: totalPages
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return MarketplaceListResponse(
                data: [],
                pagination: PostListResponse.Pagination(
                    page: 1,
                    limit: limit,
                    total: 0,
                    totalPages: 1
                )
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset all call tracking flags
    func resetCallTracking() {
        updateProfileNameCalled = false
        getUserCommentsCalled = false
        getUserPostsCalled = false
        getUserInternshipsCalled = false
        getUserMarketplacesCalled = false
    }
    
    /// Reset all behaviors to success
    func resetBehaviors() {
        updateProfileNameBehavior = .success
        getUserCommentsBehavior = .success
        getUserPostsBehavior = .success
        getUserInternshipsBehavior = .success
        getUserMarketplacesBehavior = .success
    }
    
    /// Configure all methods to fail with specific error
    func configureAllToFail(with error: Error) {
        updateProfileNameBehavior = .failure(error)
        getUserCommentsBehavior = .failure(error)
        getUserPostsBehavior = .failure(error)
        getUserInternshipsBehavior = .failure(error)
        getUserMarketplacesBehavior = .failure(error)
    }
    
    /// Configure all methods to return empty state
    func configureAllToEmptyState() {
        updateProfileNameBehavior = .emptyState
        getUserCommentsBehavior = .emptyState
        getUserPostsBehavior = .emptyState
        getUserInternshipsBehavior = .emptyState
        getUserMarketplacesBehavior = .emptyState
    }
    
    /// Clear all mock data
    func clearMockData() {
        mockUser = nil
        mockComments = []
        mockPosts = []
        mockInternships = []
        mockMarketplaceItems = []
    }
}
