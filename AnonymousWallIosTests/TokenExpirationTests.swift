//
//  TokenExpirationTests.swift
//  AnonymousWallIosTests
//
//  Tests for token expiration and unauthorized access handling
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct TokenExpirationTests {
    
    // MARK: - 401 Unauthorized Error Tests
    
    @Test func testFetchPostsWithExpiredToken() async throws {
        let mockPostService = MockPostService()
        mockPostService.fetchPostsBehavior = .failure(NetworkError.unauthorized)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("Unauthorized") == true || 
                viewModel.errorMessage?.contains("login") == true)
        #expect(viewModel.posts.isEmpty)
    }
    
    @Test func testToggleLikeWithExpiredToken() async throws {
        let mockPostService = MockPostService()
        mockPostService.toggleLikeBehavior = .failure(NetworkError.unauthorized)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        let mockPost = createMockPost(id: "1", title: "Test Post")
        viewModel.posts = [mockPost]
        
        viewModel.toggleLike(for: mockPost, authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
    }
    
    @Test func testDeletePostWithExpiredToken() async throws {
        let mockPostService = MockPostService()
        mockPostService.hidePostBehavior = .failure(NetworkError.unauthorized)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        let mockPost = createMockPost(id: "1", title: "Test Post")
        viewModel.posts = [mockPost]
        
        viewModel.deletePost(mockPost, authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("expired") == true ||
                viewModel.errorMessage?.contains("Session expired") == true)
    }
    
    @Test func testCreatePostWithExpiredToken() async throws {
        let mockPostService = MockPostService()
        mockPostService.createPostBehavior = .failure(NetworkError.unauthorized)
        
        let viewModel = CreatePostViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.postTitle = "Test Title"
        viewModel.postContent = "Test Content"
        
        await viewModel.createPost(authState: authState)
        
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isCreatingPost)
    }
    
    @Test func testFetchProfileWithExpiredToken() async throws {
        let mockUserService = MockUserService()
        mockUserService.fetchMyPostsBehavior = .failure(MockUserService.MockError.unauthorized)
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: MockPostService())
        let authState = createMockAuthState()
        
        viewModel.loadContent(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.myPosts.isEmpty)
    }
    
    // MARK: - Missing Token Tests
    
    @Test func testLoadPostsWithoutToken() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = AuthState(loadPersistedState: false) // No token
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Should not call service without token
        #expect(mockPostService.fetchPostsCalled == false)
        #expect(viewModel.posts.isEmpty)
    }
    
    @Test func testToggleLikeWithoutToken() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = AuthState(loadPersistedState: false) // No token
        
        let mockPost = createMockPost(id: "1", title: "Test Post")
        viewModel.posts = [mockPost]
        
        viewModel.toggleLike(for: mockPost, authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Should not call service without token
        #expect(mockPostService.toggleLikeCalled == false)
    }
    
    @Test func testDeletePostWithoutToken() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = AuthState(loadPersistedState: false) // No token
        
        let mockPost = createMockPost(id: "1", title: "Test Post")
        viewModel.posts = [mockPost]
        
        viewModel.deletePost(mockPost, authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Should show error without token
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("Authentication required") == true)
    }
    
    @Test func testCreatePostWithoutToken() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        let authState = AuthState(loadPersistedState: false) // No token
        
        viewModel.postTitle = "Test Title"
        viewModel.postContent = "Test Content"
        
        await viewModel.createPost(authState: authState)
        
        // Should not call service without token
        #expect(mockPostService.createPostCalled == false)
        #expect(viewModel.errorMessage != nil)
    }
    
    // MARK: - Missing User ID Tests
    
    @Test func testLoadPostsWithoutUserId() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = AuthState(loadPersistedState: false)
        authState.authToken = "test-token" // Has token but no user
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Should not call service without user ID
        #expect(mockPostService.fetchPostsCalled == false)
    }
    
    @Test func testToggleLikeWithoutUserId() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = AuthState(loadPersistedState: false)
        authState.authToken = "test-token" // Has token but no user
        
        let mockPost = createMockPost(id: "1", title: "Test Post")
        viewModel.posts = [mockPost]
        
        viewModel.toggleLike(for: mockPost, authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Should not call service without user ID
        #expect(mockPostService.toggleLikeCalled == false)
    }
    
    // MARK: - 403 Forbidden Error Tests
    
    @Test func testDeletePostWithForbiddenError() async throws {
        let mockPostService = MockPostService()
        mockPostService.hidePostBehavior = .failure(NetworkError.forbidden)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        let mockPost = createMockPost(id: "1", title: "Test Post")
        viewModel.posts = [mockPost]
        
        viewModel.deletePost(mockPost, authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("permission") == true ||
                viewModel.errorMessage?.contains("don't have permission") == true)
    }
    
    @Test func testFetchPostWithForbiddenError() async throws {
        let mockPostService = MockPostService()
        mockPostService.getPostBehavior = .failure(NetworkError.forbidden)
        
        let viewModel = PostDetailViewModel(postId: "test-post-id", postService: mockPostService)
        let authState = createMockAuthState()
        
        await viewModel.loadPost(authState: authState)
        
        #expect(viewModel.errorMessage != nil)
    }
    
    // MARK: - Error Message Formatting Tests
    
    @Test func testUnauthorizedErrorMessageFormat() async throws {
        let mockPostService = MockPostService()
        mockPostService.fetchPostsBehavior = .failure(NetworkError.unauthorized)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Error message should be user-friendly
        #expect(viewModel.errorMessage != nil)
        let errorMsg = viewModel.errorMessage?.lowercased() ?? ""
        #expect(errorMsg.contains("unauthorized") || errorMsg.contains("login"))
    }
    
    @Test func testForbiddenErrorMessageFormat() async throws {
        let mockPostService = MockPostService()
        mockPostService.hidePostBehavior = .failure(NetworkError.forbidden)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        let mockPost = createMockPost(id: "1", title: "Test Post")
        viewModel.posts = [mockPost]
        
        viewModel.deletePost(mockPost, authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Error message should be user-friendly
        #expect(viewModel.errorMessage != nil)
        let errorMsg = viewModel.errorMessage?.lowercased() ?? ""
        #expect(errorMsg.contains("permission") || errorMsg.contains("forbidden"))
    }
    
    // MARK: - State Recovery Tests
    
    @Test func testStateRecoveryAfterUnauthorized() async throws {
        let mockPostService = MockPostService()
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // First request fails with unauthorized
        mockPostService.fetchPostsBehavior = .failure(NetworkError.unauthorized)
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(viewModel.errorMessage != nil)
        
        // User re-authenticates, next request succeeds
        mockPostService.fetchPostsBehavior = .success
        mockPostService.mockPosts = [createMockPost(id: "1", title: "Post 1")]
        await viewModel.refreshPosts(authState: authState)
        
        // Should recover
        #expect(viewModel.posts.count == 1)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testMultipleUnauthorizedErrors() async throws {
        let mockPostService = MockPostService()
        mockPostService.fetchPostsBehavior = .failure(NetworkError.unauthorized)
        
        let viewModel = HomeViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // Multiple unauthorized attempts
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
        #expect(!viewModel.isLoadingPosts)
    }
    
    // MARK: - NetworkError Equality Tests
    
    @Test func testUnauthorizedErrorEquality() {
        let error1 = NetworkError.unauthorized
        let error2 = NetworkError.unauthorized
        
        // Test error description consistency
        #expect(error1.errorDescription == error2.errorDescription)
    }
    
    @Test func testForbiddenErrorEquality() {
        let error1 = NetworkError.forbidden
        let error2 = NetworkError.forbidden
        
        // Test error description consistency
        #expect(error1.errorDescription == error2.errorDescription)
    }
    
    // MARK: - Profile ViewModel Token Expiration Tests
    
    @Test func testProfileLoadPostsWithExpiredToken() async throws {
        let mockUserService = MockUserService()
        mockUserService.fetchMyPostsBehavior = .failure(MockUserService.MockError.unauthorized)
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: MockPostService())
        let authState = createMockAuthState()
        
        viewModel.selectedSegment = 0
        viewModel.loadContent(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
    }
    
    @Test func testProfileLoadCommentsWithExpiredToken() async throws {
        let mockUserService = MockUserService()
        mockUserService.fetchMyCommentsBehavior = .failure(MockUserService.MockError.unauthorized)
        
        let viewModel = ProfileViewModel(userService: mockUserService, postService: MockPostService())
        let authState = createMockAuthState()
        
        viewModel.selectedSegment = 1
        viewModel.loadContent(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
    }
    
    // MARK: - Campus ViewModel Token Expiration Tests
    
    @Test func testCampusLoadPostsWithExpiredToken() async throws {
        let mockPostService = MockPostService()
        mockPostService.fetchPostsBehavior = .failure(NetworkError.unauthorized)
        
        let viewModel = CampusViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.loadPosts(authState: authState)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        #expect(viewModel.errorMessage != nil)
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
}
