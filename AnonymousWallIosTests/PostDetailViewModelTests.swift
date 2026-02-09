//
//  PostDetailViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for PostDetailViewModel - comments, pagination, error handling
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct PostDetailViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let viewModel = PostDetailViewModel()
        
        #expect(viewModel.comments.isEmpty)
        #expect(viewModel.isLoadingComments == false)
        #expect(viewModel.isLoadingMoreComments == false)
        #expect(viewModel.commentText.isEmpty)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.commentToDelete == nil)
        #expect(viewModel.selectedSortOrder == .newest)
    }
    
    // MARK: - Submit Comment Tests
    
    @Test func testSubmitCommentWithEmptyText() async throws {
        let viewModel = PostDetailViewModel()
        let authState = createMockAuthState()
        
        viewModel.commentText = ""
        
        var successCalled = false
        viewModel.submitComment(postId: "post-1", authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Comment cannot be empty")
        #expect(successCalled == false)
    }
    
    @Test func testSubmitCommentWithWhitespaceOnly() async throws {
        let viewModel = PostDetailViewModel()
        let authState = createMockAuthState()
        
        viewModel.commentText = "   \n  "
        
        var successCalled = false
        viewModel.submitComment(postId: "post-1", authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Comment cannot be empty")
        #expect(successCalled == false)
    }
    
    @Test func testSubmitCommentWithoutAuthentication() async throws {
        let viewModel = PostDetailViewModel()
        let authState = AuthState(loadPersistedState: false) // Not authenticated
        
        viewModel.commentText = "Test comment"
        
        var successCalled = false
        viewModel.submitComment(postId: "post-1", authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Not authenticated")
        #expect(successCalled == false)
    }
    
    @Test func testSubmitCommentSuccess() async throws {
        let viewModel = PostDetailViewModel()
        let authState = createMockAuthState()
        
        viewModel.commentText = "Great post!"
        
        var successCalled = false
        viewModel.submitComment(postId: "post-1", authState: authState) {
            successCalled = true
        }
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 500_000_000) // 0.2 seconds
        
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.commentText.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
    }
    
    // MARK: - Validation Tests
    
    @Test func testCommentTextTrimming() async throws {
        let viewModel = PostDetailViewModel()
        let authState = createMockAuthState()
        
        viewModel.commentText = "  Test comment with spaces  "
        
        var successCalled = false
        viewModel.submitComment(postId: "post-1", authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // After successful submission, comment text should be cleared
        #expect(viewModel.commentText.isEmpty)
        #expect(successCalled == true)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testErrorMessageClearedOnNewSubmit() async throws {
        let viewModel = PostDetailViewModel()
        let authState = createMockAuthState()
        
        // First attempt with empty comment
        viewModel.commentText = ""
        viewModel.submitComment(postId: "post-1", authState: authState) {}
        #expect(viewModel.errorMessage == "Comment cannot be empty")
        
        // Second attempt with valid comment should clear error
        viewModel.commentText = "Valid comment"
        viewModel.submitComment(postId: "post-1", authState: authState) {}
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Sorting Tests
    
    @Test func testSortOrderChanged() async throws {
        let viewModel = PostDetailViewModel()
        let authState = createMockAuthState()
        
        #expect(viewModel.selectedSortOrder == .newest)
        
        viewModel.selectedSortOrder = .oldest
        viewModel.sortOrderChanged(postId: "post-1", authState: authState)
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.selectedSortOrder == .oldest)
    }
    
    @Test func testSortOrderChangeClearsComments() async throws {
        let viewModel = PostDetailViewModel()
        let authState = createMockAuthState()
        
        // Add some comments manually to simulate loaded state
        viewModel.comments = [
            createMockComment(id: "1", text: "Comment 1"),
            createMockComment(id: "2", text: "Comment 2")
        ]
        
        #expect(viewModel.comments.count == 2)
        
        viewModel.sortOrderChanged(postId: "post-1", authState: authState)
        
        // Comments should be cleared immediately when sort changes
        #expect(viewModel.comments.isEmpty)
    }
    
    // MARK: - State Management Tests
    
    @Test func testInitialState() async throws {
        let viewModel = PostDetailViewModel()
        
        #expect(viewModel.comments.isEmpty)
        #expect(viewModel.isLoadingComments == false)
        #expect(viewModel.isLoadingMoreComments == false)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testCommentTextClearedAfterSuccessfulSubmit() async throws {
        let viewModel = PostDetailViewModel()
        let authState = createMockAuthState()
        
        viewModel.commentText = "Test comment"
        #expect(!viewModel.commentText.isEmpty)
        
        viewModel.submitComment(postId: "post-1", authState: authState) {}
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.commentText.isEmpty)
    }
    
    // MARK: - Authentication Tests
    
    @Test func testSubmitCommentRequiresAuthentication() async throws {
        let viewModel = PostDetailViewModel()
        let authState = AuthState() // No user logged in
        
        viewModel.commentText = "Test comment"
        
        viewModel.submitComment(postId: "post-1", authState: authState) {}
        
        #expect(viewModel.errorMessage == "Not authenticated")
    }
    
    @Test func testDeleteCommentRequiresAuthentication() async throws {
        let viewModel = PostDetailViewModel()
        let authState = AuthState() // No user logged in
        let comment = createMockComment(id: "1", text: "Test")
        
        viewModel.deleteComment(comment, postId: "post-1", authState: authState)
        
        #expect(viewModel.errorMessage == "Authentication required")
    }
    
    @Test func testDeletePostRequiresAuthentication() async throws {
        let viewModel = PostDetailViewModel()
        let authState = AuthState() // No user logged in
        let post = createMockPost(id: "1", title: "Test Post")
        
        viewModel.deletePost(post: post, authState: authState) {}
        
        #expect(viewModel.errorMessage == "Authentication required")
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
}
