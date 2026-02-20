//
//  ProfileViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for ProfileViewModel - user posts, comments, pagination, sorting
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct ProfileViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        
        #expect(viewModel.selectedSegment == 0)
        #expect(viewModel.myPosts.isEmpty)
        #expect(viewModel.myComments.isEmpty)
        #expect(viewModel.commentParentMap.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.postSortOrder == .newest)
        #expect(viewModel.commentSortOrder == .newest)
        #expect(viewModel.isLoadingMorePosts == false)
        #expect(viewModel.isLoadingMoreComments == false)
    }
    
    // MARK: - Dependency Injection Tests
    
    @Test func testViewModelCanBeInitializedWithMockServices() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        
        #expect(viewModel.myPosts.isEmpty)
        #expect(viewModel.myComments.isEmpty)
    }
    
    @Test func testViewModelCanBeInitializedWithDefaultServices() async throws {
        let viewModel = ProfileViewModel()
        
        #expect(viewModel.myPosts.isEmpty)
        #expect(viewModel.myComments.isEmpty)
    }
    
    // MARK: - Segment Selection Tests
    
    @Test func testSegmentChangedToComments() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Configure mock data
        mockUserService.mockComments = [
            createMockComment(id: "1", text: "Comment 1")
        ]
        
        #expect(viewModel.selectedSegment == 0) // Posts
        
        viewModel.selectedSegment = 1 // Comments
        viewModel.segmentChanged(authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.selectedSegment == 1)
    }
    
    // MARK: - Post Sort Tests
    
    @Test func testPostSortChangedToOldest() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        #expect(viewModel.postSortOrder == .newest)
        
        viewModel.postSortOrder = .oldest
        viewModel.postSortChanged(authState: authState)
        
        #expect(viewModel.postSortOrder == .oldest)
        #expect(viewModel.myPosts.isEmpty) // Should clear posts
    }
    
    @Test func testPostSortChangedToMostLiked() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.postSortOrder = .mostLiked
        viewModel.postSortChanged(authState: authState)
        
        #expect(viewModel.postSortOrder == .mostLiked)
        #expect(viewModel.myPosts.isEmpty)
    }
    
    @Test func testPostSortChangedToMostCommented() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.postSortOrder = .mostCommented
        viewModel.postSortChanged(authState: authState)
        
        #expect(viewModel.postSortOrder == .mostCommented)
        #expect(viewModel.myPosts.isEmpty)
    }
    
    @Test func testPostSortChangeClearsPosts() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Add some posts manually
        viewModel.myPosts = [
            createMockPost(id: "1", title: "Post 1"),
            createMockPost(id: "2", title: "Post 2")
        ]
        
        #expect(viewModel.myPosts.count == 2)
        
        viewModel.postSortOrder = .oldest
        viewModel.postSortChanged(authState: authState)
        
        // Posts should be cleared immediately
        #expect(viewModel.myPosts.isEmpty)
    }
    
    // MARK: - Comment Sort Tests
    
    @Test func testCommentSortChangedToOldest() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        #expect(viewModel.commentSortOrder == .newest)
        
        viewModel.commentSortOrder = .oldest
        viewModel.commentSortChanged(authState: authState)
        
        #expect(viewModel.commentSortOrder == .oldest)
        #expect(viewModel.myComments.isEmpty) // Should clear comments
    }
    
    @Test func testCommentSortChangeClearsComments() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Add some comments manually
        viewModel.myComments = [
            createMockComment(id: "1", text: "Comment 1"),
            createMockComment(id: "2", text: "Comment 2")
        ]
        
        #expect(viewModel.myComments.count == 2)
        
        viewModel.commentSortOrder = .oldest
        viewModel.commentSortChanged(authState: authState)
        
        // Comments should be cleared immediately
        #expect(viewModel.myComments.isEmpty)
    }
    
    // MARK: - Pagination Tests
    
    @Test func testInitialPaginationState() async throws {
        let viewModel = ProfileViewModel()
        
        // Pagination state is private - we can only test public loading state indicators
        #expect(viewModel.isLoadingMorePosts == false)
        #expect(viewModel.isLoadingMoreComments == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testErrorMessageInitiallyNil() async throws {
        let viewModel = ProfileViewModel()
        
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - State Management Tests
    
    @Test func testSegmentChangeTracking() async throws {
        let viewModel = ProfileViewModel()
        
        #expect(viewModel.selectedSegment == 0)
        
        viewModel.selectedSegment = 1
        #expect(viewModel.selectedSegment == 1)
        
        viewModel.selectedSegment = 0
        #expect(viewModel.selectedSegment == 0)
    }
    
    @Test func testCommentParentMapInitiallyEmpty() async throws {
        let viewModel = ProfileViewModel()
        
        #expect(viewModel.commentParentMap.isEmpty)
    }
    
    @Test func testCommentParentMapClearedOnSort() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        // Add some data to commentParentMap
        let mockPost = createMockPost(id: "post-1", title: "Test Post")
        viewModel.commentParentMap["comment-1"] = .post(mockPost)
        
        #expect(!viewModel.commentParentMap.isEmpty)
        
        viewModel.commentSortOrder = .oldest
        viewModel.commentSortChanged(authState: authState)
        
        // Should be cleared on sort change
        #expect(viewModel.commentParentMap.isEmpty)
    }
    
    // MARK: - Refresh Tests
    
    @Test func testRefreshContentOnPostsSegment() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.selectedSegment = 0 // Posts segment
        
        await viewModel.refreshContent(authState: authState)
        
        // Pagination is reset internally - we can verify via behavior (posts are reloaded)
        // No direct pagination state is exposed in the public API
    }
    
    @Test func testRefreshContentOnCommentsSegment() async throws {
        let mockUserService = MockUserService()
        let mockPostService = MockPostService()
        let viewModel = ProfileViewModel(userService: mockUserService, postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.selectedSegment = 1 // Comments segment
        
        await viewModel.refreshContent(authState: authState)
        
        // Pagination is reset internally - we can verify via behavior (comments are reloaded)
        // No direct pagination state is exposed in the public API
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
            createdAt: "2026-02-09T00:00:00Z"
        )
        authState.currentUser = mockUser
        authState.authToken = "test-token"
        return authState
    }
    
    private func createMockPost(id: String, title: String) -> Post {
        return Post(
            id: id,
            title: title,
            content: "Test content",
            wall: "NATIONAL",
            likes: 0,
            comments: 0,
            liked: false,
            author: Post.Author(
                id: "author-id",
                profileName: "Test Author",
                isAnonymous: true
            ),
            createdAt: "2026-02-09T00:00:00Z",
            updatedAt: "2026-02-09T00:00:00Z"
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
            createdAt: "2026-02-09T00:00:00Z"
        )
    }
}
