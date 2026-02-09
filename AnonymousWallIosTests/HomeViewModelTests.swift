//
//  HomeViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for HomeViewModel demonstrating dependency injection
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct HomeViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelCanBeInitializedWithMockService() async throws {
        // Verify that HomeViewModel can be initialized with a mock service
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        
        // Verify initial state
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.isLoadingPosts == false)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.selectedSortOrder == .newest)
    }
    
    @Test func testViewModelCanBeInitializedWithDefaultService() async throws {
        // Verify that HomeViewModel can be initialized with default service
        let viewModel = HomeViewModel()
        
        // Verify initial state
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.isLoadingPosts == false)
    }
    
    // MARK: - Load Posts Tests
    
    @Test func testLoadPostsCallsPostService() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add mock data
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Test Post 1"),
            createMockPost(id: "2", title: "Test Post 2")
        ]
        
        // Execute
        viewModel.loadPosts(authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.1 seconds
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.posts.count == 2)
        #expect(viewModel.posts[0].title == "Test Post 1")
        #expect(viewModel.posts[1].title == "Test Post 2")
    }
    
    @Test func testLoadPostsHandlesEmptyResponse() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Configure to return empty state
        mockPostService.fetchPostsBehavior = .emptyState
        
        // Execute
        viewModel.loadPosts(authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.1 seconds
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.posts.isEmpty)
    }
    
    @Test func testLoadPostsHandlesFailure() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Configure to fail
        mockPostService.fetchPostsBehavior = .failure(MockPostService.MockError.networkError)
        
        // Execute
        viewModel.loadPosts(authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.1 seconds
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.posts.isEmpty)
    }
    
    // MARK: - Toggle Like Tests
    
    @Test func testToggleLikeCallsPostService() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add a mock post to the view model
        let mockPost = createMockPost(id: "1", title: "Test Post", likes: 5, liked: false)
        viewModel.posts = [mockPost]
        
        // Configure mock like response
        mockPostService.mockLikeResponse = LikeResponse(liked: true, likeCount: 6)
        
        // Execute
        viewModel.toggleLike(for: mockPost, authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.1 seconds
        
        // Verify
        #expect(mockPostService.toggleLikeCalled == true)
        #expect(viewModel.posts[0].liked == true)
        #expect(viewModel.posts[0].likes == 6)
    }
    
    // MARK: - Delete Post Tests
    
    @Test func testDeletePostCallsPostService() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add mock posts
        let mockPost1 = createMockPost(id: "1", title: "Test Post 1")
        let mockPost2 = createMockPost(id: "2", title: "Test Post 2")
        mockPostService.mockPosts = [mockPost2] // Only one post will remain after delete
        viewModel.posts = [mockPost1, mockPost2]
        
        // Execute
        viewModel.deletePost(mockPost1, authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify
        #expect(mockPostService.hidePostCalled == true)
        // After delete, posts are reloaded, so we should have only 1 post
        #expect(viewModel.posts.count == 1)
        #expect(viewModel.posts[0].id == "2")
    }
    
    // MARK: - Refresh Posts Tests
    
    @Test func testRefreshPostsCallsPostService() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add initial data
        viewModel.posts = [createMockPost(id: "old", title: "Old Post")]
        
        // Configure new data
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "New Post 1"),
            createMockPost(id: "2", title: "New Post 2")
        ]
        
        // Execute
        await viewModel.refreshPosts(authState: mockAuthState)
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.posts.count == 2)
        #expect(viewModel.posts[0].title == "New Post 1")
    }
    
    // MARK: - Helper Methods
    
    private func createMockAuthState() -> AuthState {
        let authState = AuthState()
        let mockUser = User(
            id: "test-user-id",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01T00:00:00Z"
        )
        authState.currentUser = mockUser
        authState.authToken = "test-token"
        return authState
    }
    
    private func createMockPost(
        id: String,
        title: String,
        content: String = "Test content",
        likes: Int = 0,
        liked: Bool = false
    ) -> Post {
        return Post(
            id: id,
            title: title,
            content: content,
            wall: "NATIONAL",
            likes: likes,
            comments: 0,
            liked: liked,
            author: Post.Author(
                id: "author-id",
                profileName: "Test Author",
                isAnonymous: true
            ),
            createdAt: "2026-02-01T00:00:00Z",
            updatedAt: "2026-02-01T00:00:00Z"
        )
    }
    
    // MARK: - Report Post Tests
    
    @Test func testReportPostSuccess() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        let post = createMockPost(id: "post-1", title: "Test Post")
        
        mockPostService.mockReportResponse = ReportResponse(message: "Post reported successfully")
        
        // Execute
        viewModel.reportPost(post, reason: "Spam content", authState: mockAuthState)
        
        // Allow async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify
        #expect(mockPostService.reportPostCalled == true)
        #expect(viewModel.showReportSuccess == true)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testReportPostWithoutReason() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        let post = createMockPost(id: "post-1", title: "Test Post")
        
        mockPostService.mockReportResponse = ReportResponse(message: "Post reported successfully")
        
        // Execute
        viewModel.reportPost(post, reason: nil, authState: mockAuthState)
        
        // Allow async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify
        #expect(mockPostService.reportPostCalled == true)
        #expect(viewModel.showReportSuccess == true)
    }
    
    @Test func testReportPostWithoutAuthentication() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = AuthState(loadPersistedState: false) // Not authenticated
        let post = createMockPost(id: "post-1", title: "Test Post")
        
        // Execute
        viewModel.reportPost(post, reason: "Test", authState: authState)
        
        // Verify
        #expect(mockPostService.reportPostCalled == false)
        #expect(viewModel.errorMessage == "Authentication required to report post.")
    }
    
    @Test func testReportPostFailure() async throws {
        // Setup
        let mockPostService = MockPostService()
        mockPostService.reportPostBehavior = .failure(MockPostService.MockError.serverError)
        let viewModel = HomeViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        let post = createMockPost(id: "post-1", title: "Test Post")
        
        // Execute
        viewModel.reportPost(post, reason: "Test", authState: mockAuthState)
        
        // Allow async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify
        #expect(mockPostService.reportPostCalled == true)
        #expect(viewModel.errorMessage?.contains("Failed to report post") == true)
    }
}
