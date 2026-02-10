//
//  CampusViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for CampusViewModel demonstrating dependency injection
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct CampusViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelCanBeInitializedWithMockService() async throws {
        // Verify that CampusViewModel can be initialized with a mock service
        let mockPostService = MockPostService()
        let viewModel = CampusViewModel(postService: mockPostService)
        
        // Verify initial state
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.isLoadingPosts == false)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.selectedSortOrder == .newest)
    }
    
    @Test func testViewModelCanBeInitializedWithDefaultService() async throws {
        // Verify that CampusViewModel can be initialized with default service
        let viewModel = CampusViewModel()
        
        // Verify initial state
        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.isLoadingPosts == false)
    }
    
    // MARK: - Load Posts Tests
    
    @Test func testLoadPostsCallsPostService() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = CampusViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add mock data
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Campus Post 1", wall: "CAMPUS"),
            createMockPost(id: "2", title: "Campus Post 2", wall: "CAMPUS")
        ]
        
        // Execute
        viewModel.loadPosts(authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.posts.count == 2)
        #expect(viewModel.posts[0].title == "Campus Post 1")
        #expect(viewModel.posts[1].title == "Campus Post 2")
        #expect(viewModel.posts[0].wall == "CAMPUS")
    }
    
    @Test func testLoadPostsHandlesEmptyResponse() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = CampusViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Configure to return empty state
        mockPostService.fetchPostsBehavior = .emptyState
        
        // Execute
        viewModel.loadPosts(authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.posts.isEmpty)
    }
    
    @Test func testLoadPostsHandlesFailure() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = CampusViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Configure to fail
        mockPostService.fetchPostsBehavior = .failure(MockPostService.MockError.networkError)
        
        // Execute
        viewModel.loadPosts(authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.posts.isEmpty)
    }
    
    // MARK: - Toggle Like Tests
    
    @Test func testToggleLikeCallsPostService() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = CampusViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add a mock post to the view model
        let mockPost = createMockPost(id: "1", title: "Campus Post", wall: "CAMPUS", likes: 5, liked: false)
        viewModel.posts = [mockPost]
        
        // Configure mock like response
        mockPostService.mockLikeResponse = LikeResponse(liked: true, likeCount: 6)
        
        // Execute
        viewModel.toggleLike(for: mockPost, authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify
        #expect(mockPostService.toggleLikeCalled == true)
        #expect(viewModel.posts[0].liked == true)
        #expect(viewModel.posts[0].likes == 6)
    }
    
    // MARK: - Delete Post Tests
    
    @Test func testDeletePostCallsPostService() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = CampusViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add mock posts
        let mockPost1 = createMockPost(id: "1", title: "Campus Post 1", wall: "CAMPUS")
        let mockPost2 = createMockPost(id: "2", title: "Campus Post 2", wall: "CAMPUS")
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
        let viewModel = CampusViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add initial data
        viewModel.posts = [createMockPost(id: "old", title: "Old Post", wall: "CAMPUS")]
        
        // Configure new data
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "New Campus Post 1", wall: "CAMPUS"),
            createMockPost(id: "2", title: "New Campus Post 2", wall: "CAMPUS")
        ]
        
        // Execute
        await viewModel.refreshPosts(authState: mockAuthState)
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.posts.count == 2)
        #expect(viewModel.posts[0].title == "New Campus Post 1")
    }
    
    // MARK: - Sort Order Tests
    
    @Test func testSortOrderChangedCallsLoadPosts() async throws {
        // Setup
        let mockPostService = MockPostService()
        let viewModel = CampusViewModel(postService: mockPostService)
        let mockAuthState = createMockAuthState()
        
        // Add initial data
        viewModel.posts = [createMockPost(id: "1", title: "Post 1", wall: "CAMPUS")]
        
        // Configure new data for reload
        mockPostService.mockPosts = [
            createMockPost(id: "2", title: "Post 2", wall: "CAMPUS"),
            createMockPost(id: "3", title: "Post 3", wall: "CAMPUS")
        ]
        
        // Execute
        viewModel.selectedSortOrder = .mostLiked
        viewModel.sortOrderChanged(authState: mockAuthState)
        
        // Wait for async operation to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify
        #expect(mockPostService.fetchPostsCalled == true)
        #expect(viewModel.posts.count == 2)
        #expect(viewModel.selectedSortOrder == .mostLiked)
    }
    
    // MARK: - Helper Methods
    
    private func createMockAuthState() -> AuthState {
        let authState = AuthState()
        let mockUser = User(
            id: "test-user-id",
            email: "test@example.edu",
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
        wall: String = "CAMPUS",
        content: String = "Test content",
        likes: Int = 0,
        liked: Bool = false
    ) -> Post {
        return Post(
            id: id,
            title: title,
            content: content,
            wall: wall,
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
}
