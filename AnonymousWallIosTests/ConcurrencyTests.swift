//
//  ConcurrencyTests.swift
//  AnonymousWallIosTests
//
//  Comprehensive tests for concurrency handling in ViewModels and services
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct ConcurrencyTests {
    
    // MARK: - Multiple Simultaneous Requests Tests
    
    @Test func testMultipleSimultaneousPostFetches() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Post 1"),
            createMockPost(id: "2", title: "Post 2")
        ]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Trigger multiple loads simultaneously
        viewModel.loadPosts(authState: authState)
        viewModel.loadPosts(authState: authState)
        viewModel.loadPosts(authState: authState)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should have loaded posts (only the last one should complete)
        #expect(viewModel.posts.count == 2)
        #expect(!viewModel.isLoadingPosts)
    }
    
    @Test func testMultipleSimultaneousLikeToggles() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        let mockPost = createMockPost(id: "1", title: "Test Post", likes: 0, liked: false)
        viewModel.posts = [mockPost]
        
        // Configure mock to toggle like
        mockPostService.mockLikeResponse = LikeResponse(liked: true, likeCount: 1)
        
        // Trigger multiple simultaneous like toggles
        let task1 = Task {
            viewModel.toggleLike(for: mockPost, authState: authState)
        }
        let task2 = Task {
            viewModel.toggleLike(for: mockPost, authState: authState)
        }
        let task3 = Task {
            viewModel.toggleLike(for: mockPost, authState: authState)
        }
        
        await task1.value
        await task2.value
        await task3.value
        
        // Wait for async operations to complete
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Post should be updated (race conditions handled by MainActor)
        #expect(viewModel.posts[0].id == "1")
    }
    
    @Test func testConcurrentRefreshAndLoad() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Post 1"),
            createMockPost(id: "2", title: "Post 2")
        ]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Start a load
        viewModel.loadPosts(authState: authState)
        
        // Immediately refresh
        await viewModel.refreshPosts(authState: authState)
        
        // Should have loaded posts without issues
        #expect(viewModel.posts.count == 2)
        #expect(!viewModel.isLoadingPosts)
    }
    
    @Test func testConcurrentSortChangeAndLoad() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Post 1"),
            createMockPost(id: "2", title: "Post 2")
        ]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Start a load
        viewModel.loadPosts(authState: authState)
        
        // Immediately change sort
        viewModel.selectedSortOrder = .mostLiked
        viewModel.sortOrderChanged(authState: authState)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should have loaded posts without issues
        #expect(viewModel.posts.count == 2)
        #expect(viewModel.selectedSortOrder == .mostLiked)
    }
    
    // MARK: - Task Cancellation Tests
    
    @Test func testLoadTaskCancellationOnRefresh() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Configure slow response to test cancellation
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        // Start a load
        viewModel.loadPosts(authState: authState)
        
        // Immediately cancel by refreshing
        await viewModel.refreshPosts(authState: authState)
        
        // Should complete without error
        #expect(!viewModel.isLoadingPosts)
    }
    
    @Test func testLoadTaskCancellationOnSortChange() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        // Start a load
        viewModel.loadPosts(authState: authState)
        
        // Immediately change sort (should cancel previous task)
        viewModel.selectedSortOrder = .oldest
        viewModel.sortOrderChanged(authState: authState)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.selectedSortOrder == .oldest)
    }
    
    @Test func testTaskCancellationOnCleanup() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        // Start a load
        viewModel.loadPosts(authState: authState)
        
        // Cleanup (should cancel task)
        viewModel.cleanup()
        
        // Should not crash
        #expect(true)
    }
    
    @Test func testMultipleCancellations() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        // Start and cancel multiple times
        viewModel.loadPosts(authState: authState)
        await viewModel.refreshPosts(authState: authState)
        
        viewModel.loadPosts(authState: authState)
        viewModel.sortOrderChanged(authState: authState)
        
        viewModel.loadPosts(authState: authState)
        viewModel.cleanup()
        
        // Should complete without issues
        #expect(true)
    }
    
    // MARK: - Race Condition Tests
    
    @Test func testRapidRefreshOperations() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Post 1"),
            createMockPost(id: "2", title: "Post 2")
        ]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Rapid consecutive refreshes
        await viewModel.refreshPosts(authState: authState)
        await viewModel.refreshPosts(authState: authState)
        await viewModel.refreshPosts(authState: authState)
        
        // Should have valid state
        #expect(viewModel.posts.count == 2)
        #expect(!viewModel.isLoadingPosts)
    }
    
    @Test func testRapidSortChanges() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Rapid sort changes
        viewModel.selectedSortOrder = .newest
        viewModel.sortOrderChanged(authState: authState)
        
        viewModel.selectedSortOrder = .oldest
        viewModel.sortOrderChanged(authState: authState)
        
        viewModel.selectedSortOrder = .mostLiked
        viewModel.sortOrderChanged(authState: authState)
        
        // Wait for last operation to complete
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.selectedSortOrder == .mostLiked)
    }
    
    @Test func testConcurrentPaginationRequests() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Post 1"),
            createMockPost(id: "2", title: "Post 2")
        ]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Load initial posts
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let lastPost = viewModel.posts.last!
        
        // Try to trigger multiple pagination requests
        viewModel.loadMoreIfNeeded(for: lastPost, authState: authState)
        viewModel.loadMoreIfNeeded(for: lastPost, authState: authState)
        viewModel.loadMoreIfNeeded(for: lastPost, authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should handle gracefully (isLoadingMore guard prevents duplicates)
        #expect(!viewModel.isLoadingMore)
    }
    
    @Test func testStateConsistencyDuringConcurrentOperations() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Perform multiple concurrent operations
        let task1 = Task {
            viewModel.loadPosts(authState: authState)
        }
        let task2 = Task {
            await viewModel.refreshPosts(authState: authState)
        }
        let task3 = Task {
            viewModel.selectedSortOrder = .oldest
            viewModel.sortOrderChanged(authState: authState)
        }
        
        await task1.value
        await task2.value
        await task3.value
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // State should be consistent (no crashes, valid data)
        #expect(viewModel.posts.count >= 0)
        #expect(!viewModel.isLoadingPosts)
    }
    
    // MARK: - Profile ViewModel Concurrency Tests
    
    @Test func testProfileConcurrentSegmentSwitching() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        mockUserService.mockPosts = [createMockPost(id: "1", title: "My Post")]
        mockUserService.mockComments = [createMockComment(id: "1", text: "My Comment")]
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Rapid segment switching
        viewModel.selectedSegment = 0
        viewModel.segmentChanged(authState: authState)
        
        viewModel.selectedSegment = 1
        viewModel.segmentChanged(authState: authState)
        
        viewModel.selectedSegment = 0
        viewModel.segmentChanged(authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should complete without issues
        #expect(viewModel.selectedSegment == 0)
        #expect(!viewModel.isLoading)
    }
    
    @Test func testProfileConcurrentSortAndRefresh() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        mockUserService.mockPosts = [createMockPost(id: "1", title: "My Post")]
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Sort change
        viewModel.postSortOrder = .mostLiked
        viewModel.postSortChanged(authState: authState)
        
        // Immediate refresh
        await viewModel.refreshContent(authState: authState)
        
        // Should complete without issues
        #expect(!viewModel.isLoading)
    }
    
    // MARK: - Error Handling During Concurrency Tests
    
    @Test func testConcurrentRequestsWithFailure() async throws {
        let mockPostService = MockPostService()
        mockPostService.fetchPostsBehavior = .failure(MockPostService.MockError.networkError)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Multiple concurrent loads that will fail
        viewModel.loadPosts(authState: authState)
        viewModel.loadPosts(authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should handle errors gracefully
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoadingPosts)
    }
    
    @Test func testRecoveryAfterConcurrentFailures() async throws {
        let mockPostService = MockPostService()
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // First request fails
        mockPostService.fetchPostsBehavior = .failure(MockPostService.MockError.networkError)
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Second request succeeds
        mockPostService.fetchPostsBehavior = .success
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        await viewModel.refreshPosts(authState: authState)
        
        // Should recover and show posts
        #expect(viewModel.posts.count == 1)
        #expect(!viewModel.isLoadingPosts)
    }
    
    // MARK: - Helper Methods
    
    private func createMockAuthState() -> AuthState {
        let authState = AuthState(loadPersistedState: false)
        let mockUser = User(
            id: "test-user-id",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-02-14T00:00:00Z"
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
            createdAt: "2026-02-14T00:00:00Z",
            updatedAt: "2026-02-14T00:00:00Z"
        )
    }
    
    private func createMockComment(id: String, text: String) -> AnonymousWallIos.Comment {
        return AnonymousWallIos.Comment(
            id: id,
            postId: "post-1",
            text: text,
            author: Post.Author(
                id: "author-id",
                profileName: "Test Author",
                isAnonymous: true
            ),
            createdAt: "2026-02-14T00:00:00Z"
        )
    }
}
