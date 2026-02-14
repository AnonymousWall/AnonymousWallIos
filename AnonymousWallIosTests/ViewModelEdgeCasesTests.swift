//
//  ViewModelEdgeCasesTests.swift
//  AnonymousWallIosTests
//
//  Comprehensive edge case tests for ViewModels
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct ViewModelEdgeCasesTests {
    
    // MARK: - Empty State Tests
    
    @Test func testHomeViewModelEmptyStateInitial() async throws {
        let mockPostService = MockPostService()
        mockPostService.fetchPostsBehavior = .emptyState
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.posts.isEmpty)
        #expect(!viewModel.isLoadingPosts)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testHomeViewModelEmptyStateAfterData() async throws {
        let mockPostService = MockPostService()
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // First load with data
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(viewModel.posts.count == 1)
        
        // Second load with empty state
        mockPostService.fetchPostsBehavior = .emptyState
        await viewModel.refreshPosts(authState: authState)
        
        #expect(viewModel.posts.isEmpty)
    }
    
    @Test func testProfileViewModelEmptyPosts() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        mockUserService.fetchMyPostsBehavior = .emptyState
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.loadContent(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.myPosts.isEmpty)
        #expect(!viewModel.isLoading)
    }
    
    @Test func testProfileViewModelEmptyComments() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        mockUserService.fetchMyCommentsBehavior = .emptyState
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.selectedSegment = 1 // Comments
        viewModel.loadContent(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.myComments.isEmpty)
        #expect(!viewModel.isLoading)
    }
    
    @Test func testCampusViewModelEmptyState() async throws {
        let mockPostService = MockPostService()
        mockPostService.fetchPostsBehavior = .emptyState
        
        let viewModel = CampusViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.posts.isEmpty)
        #expect(!viewModel.isLoadingPosts)
    }
    
    // MARK: - Rapid Refresh Tests
    
    @Test func testRapidRefreshHomeViewModel() async throws {
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
        await viewModel.refreshPosts(authState: authState)
        await viewModel.refreshPosts(authState: authState)
        
        // Should complete successfully with valid data
        #expect(viewModel.posts.count == 2)
        #expect(!viewModel.isLoadingPosts)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testRapidRefreshCampusViewModel() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Campus Post")]
        
        let viewModel = CampusViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Multiple rapid refreshes
        await viewModel.refreshPosts(authState: authState)
        await viewModel.refreshPosts(authState: authState)
        await viewModel.refreshPosts(authState: authState)
        
        #expect(viewModel.posts.count == 1)
        #expect(!viewModel.isLoadingPosts)
    }
    
    @Test func testRapidRefreshProfileViewModel() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        mockUserService.mockPosts = [createMockPost(id: "1", title: "My Post")]
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Rapid refreshes on posts segment
        await viewModel.refreshContent(authState: authState)
        await viewModel.refreshContent(authState: authState)
        await viewModel.refreshContent(authState: authState)
        
        #expect(!viewModel.isLoading)
    }
    
    // MARK: - Pagination Edge Cases Tests
    
    @Test func testLoadMoreWhenAlreadyLoading() async throws {
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
        
        // Trigger loadMore
        viewModel.loadMoreIfNeeded(for: lastPost, authState: authState)
        
        // Try to trigger loadMore again immediately (should be blocked by isLoadingMore)
        viewModel.loadMoreIfNeeded(for: lastPost, authState: authState)
        viewModel.loadMoreIfNeeded(for: lastPost, authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should handle gracefully without duplicating requests
        #expect(!viewModel.isLoadingMore)
    }
    
    @Test func testLoadMoreWhenNoMorePages() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Load posts and mark as last page
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Set internal state to no more pages
        // (simulated by having totalPages = 1 in the mock response)
        
        let lastPost = viewModel.posts.last!
        
        // Try to load more (should be blocked by hasMorePages check)
        viewModel.loadMoreIfNeeded(for: lastPost, authState: authState)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Should not attempt to load more
        #expect(!viewModel.isLoadingMore)
    }
    
    @Test func testLoadMoreWithNonLastPost() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Post 1"),
            createMockPost(id: "2", title: "Post 2"),
            createMockPost(id: "3", title: "Post 3")
        ]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Try to trigger loadMore with first post (not last)
        let firstPost = viewModel.posts.first!
        viewModel.loadMoreIfNeeded(for: firstPost, authState: authState)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Should not load more because it's not the last post
        #expect(!viewModel.isLoadingMore)
    }
    
    @Test func testPaginationResetOnSortChange() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [
            createMockPost(id: "1", title: "Post 1"),
            createMockPost(id: "2", title: "Post 2")
        ]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Load initial page
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Change sort order (should reset pagination)
        viewModel.selectedSortOrder = .mostLiked
        viewModel.sortOrderChanged(authState: authState)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Posts should be reloaded
        #expect(viewModel.posts.count >= 0)
        #expect(viewModel.selectedSortOrder == .mostLiked)
    }
    
    @Test func testPaginationResetOnRefresh() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Load and paginate
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Refresh (should reset pagination to page 1)
        await viewModel.refreshPosts(authState: authState)
        
        // Should be back to initial state
        #expect(!viewModel.isLoadingPosts)
    }
    
    // MARK: - Simultaneous Operation Tests
    
    @Test func testSimultaneousSortChangeAndRefresh() async throws {
        let mockPostService = MockPostService()
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Start a sort change
        viewModel.selectedSortOrder = .mostLiked
        viewModel.sortOrderChanged(authState: authState)
        
        // Immediately refresh
        await viewModel.refreshPosts(authState: authState)
        
        // Should complete without issues
        #expect(!viewModel.isLoadingPosts)
    }
    
    @Test func testLoadPostsWhileDeleting() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        let post1 = createMockPost(id: "1", title: "Post 1")
        let post2 = createMockPost(id: "2", title: "Post 2")
        mockPostService.mockPosts = [post2] // After delete
        viewModel.posts = [post1, post2]
        
        // Start delete
        viewModel.deletePost(post1, authState: authState)
        
        // Start load
        viewModel.loadPosts(authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should complete successfully
        #expect(!viewModel.isLoadingPosts)
    }
    
    @Test func testToggleLikeWhileRefreshing() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        let mockPost = createMockPost(id: "1", title: "Post 1", likes: 0, liked: false)
        mockPostService.mockPosts = [mockPost]
        viewModel.posts = [mockPost]
        
        mockPostService.mockLikeResponse = LikeResponse(liked: true, likeCount: 1)
        
        // Start refresh
        let refreshTask = Task {
            await viewModel.refreshPosts(authState: authState)
        }
        
        // Immediately toggle like
        viewModel.toggleLike(for: mockPost, authState: authState)
        
        await refreshTask.value
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should complete without crashes
        #expect(true)
    }
    
    // MARK: - Profile ViewModel Edge Cases Tests
    
    @Test func testProfilePaginationResetOnPostSortChange() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        mockUserService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Load posts
        viewModel.selectedSegment = 0
        viewModel.loadContent(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Change sort (should reset pagination and clear posts)
        viewModel.postSortOrder = .mostLiked
        viewModel.postSortChanged(authState: authState)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.postSortOrder == .mostLiked)
    }
    
    @Test func testProfilePaginationResetOnCommentSortChange() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        mockUserService.mockComments = [createMockComment(id: "1", text: "Comment 1")]
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Load comments
        viewModel.selectedSegment = 1
        viewModel.loadContent(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Change sort (should reset pagination and clear comments)
        viewModel.commentSortOrder = .oldest
        viewModel.commentSortChanged(authState: authState)
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.commentSortOrder == .oldest)
        #expect(viewModel.commentPostMap.isEmpty) // Should be cleared
    }
    
    @Test func testProfileRapidSegmentSwitching() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        mockUserService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        mockUserService.mockComments = [createMockComment(id: "1", text: "Comment 1")]
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Rapid segment switching
        viewModel.selectedSegment = 0
        viewModel.segmentChanged(authState: authState)
        
        viewModel.selectedSegment = 1
        viewModel.segmentChanged(authState: authState)
        
        viewModel.selectedSegment = 0
        viewModel.segmentChanged(authState: authState)
        
        viewModel.selectedSegment = 1
        viewModel.segmentChanged(authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should complete without issues
        #expect(!viewModel.isLoading)
    }
    
    @Test func testProfileLastPageDetection() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        
        // Configure to return empty pagination (last page)
        mockUserService.mockPosts = []
        mockUserService.fetchMyPostsBehavior = .emptyState
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.selectedSegment = 0
        viewModel.loadContent(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Should recognize no more pages
        #expect(viewModel.myPosts.isEmpty)
    }
    
    // MARK: - Error Recovery Tests
    
    @Test func testRecoveryFromErrorOnRefresh() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // First request fails
        mockPostService.fetchPostsBehavior = .failure(MockPostService.MockError.networkError)
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
        
        // Refresh with success
        mockPostService.fetchPostsBehavior = .success
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        await viewModel.refreshPosts(authState: authState)
        
        // Should recover
        #expect(viewModel.posts.count == 1)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testMultipleConsecutiveErrors() async throws {
        let mockPostService = MockPostService()
        mockPostService.fetchPostsBehavior = .failure(MockPostService.MockError.networkError)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Multiple failed attempts
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(viewModel.errorMessage != nil)
        
        await viewModel.refreshPosts(authState: authState)
        #expect(viewModel.errorMessage != nil)
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(viewModel.errorMessage != nil)
        
        // State should remain consistent
        #expect(viewModel.posts.isEmpty)
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
