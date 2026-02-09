//
//  CreatePostViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for CreatePostViewModel - post creation validation
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct CreatePostViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let viewModel = CreatePostViewModel()
        
        #expect(viewModel.postTitle.isEmpty)
        #expect(viewModel.postContent.isEmpty)
        #expect(viewModel.selectedWall == .campus)
        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Character Count Tests
    
    @Test func testTitleCharacterCount() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postTitle = "Test Title"
        #expect(viewModel.titleCharacterCount == 10)
        
        viewModel.postTitle = "A"
        #expect(viewModel.titleCharacterCount == 1)
        
        viewModel.postTitle = ""
        #expect(viewModel.titleCharacterCount == 0)
    }
    
    @Test func testContentCharacterCount() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postContent = "Test Content"
        #expect(viewModel.contentCharacterCount == 12)
        
        viewModel.postContent = "A"
        #expect(viewModel.contentCharacterCount == 1)
        
        viewModel.postContent = ""
        #expect(viewModel.contentCharacterCount == 0)
    }
    
    // MARK: - Length Limit Tests
    
    @Test func testTitleOverLimit() async throws {
        let viewModel = CreatePostViewModel()
        
        // Create a title that's exactly at the limit (255 characters)
        viewModel.postTitle = String(repeating: "a", count: 255)
        #expect(viewModel.isTitleOverLimit == false)
        
        // Create a title that's over the limit (256 characters)
        viewModel.postTitle = String(repeating: "a", count: 256)
        #expect(viewModel.isTitleOverLimit == true)
    }
    
    @Test func testContentOverLimit() async throws {
        let viewModel = CreatePostViewModel()
        
        // Create content that's exactly at the limit (5000 characters)
        viewModel.postContent = String(repeating: "a", count: 5000)
        #expect(viewModel.isContentOverLimit == false)
        
        // Create content that's over the limit (5001 characters)
        viewModel.postContent = String(repeating: "a", count: 5001)
        #expect(viewModel.isContentOverLimit == true)
    }
    
    // MARK: - Button State Tests
    
    @Test func testPostButtonDisabledWhenTitleEmpty() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postTitle = ""
        viewModel.postContent = "Some content"
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenTitleWhitespaceOnly() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postTitle = "   \n  "
        viewModel.postContent = "Some content"
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenContentEmpty() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postTitle = "Title"
        viewModel.postContent = ""
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenContentWhitespaceOnly() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postTitle = "Title"
        viewModel.postContent = "   \n  "
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenTitleTooLong() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postTitle = String(repeating: "a", count: 256)
        viewModel.postContent = "Content"
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenContentTooLong() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postTitle = "Title"
        viewModel.postContent = String(repeating: "a", count: 5001)
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonEnabledWhenValid() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.postTitle = "Valid Title"
        viewModel.postContent = "Valid content"
        
        #expect(viewModel.isPostButtonDisabled == false)
    }
    
    // MARK: - Create Post Tests
    
    @Test func testCreatePostWithEmptyTitle() async throws {
        let viewModel = CreatePostViewModel()
        let authState = createMockAuthState()
        
        viewModel.postTitle = ""
        viewModel.postContent = "Content"
        
        var successCalled = false
        viewModel.createPost(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Post title cannot be empty")
        #expect(successCalled == false)
    }
    
    @Test func testCreatePostWithEmptyContent() async throws {
        let viewModel = CreatePostViewModel()
        let authState = createMockAuthState()
        
        viewModel.postTitle = "Title"
        viewModel.postContent = ""
        
        var successCalled = false
        viewModel.createPost(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Post content cannot be empty")
        #expect(successCalled == false)
    }
    
    @Test func testCreatePostWithTitleTooLong() async throws {
        let viewModel = CreatePostViewModel()
        let authState = createMockAuthState()
        
        viewModel.postTitle = String(repeating: "a", count: 256)
        viewModel.postContent = "Content"
        
        var successCalled = false
        viewModel.createPost(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage?.contains("title exceeds maximum length") == true)
        #expect(successCalled == false)
    }
    
    @Test func testCreatePostWithContentTooLong() async throws {
        let viewModel = CreatePostViewModel()
        let authState = createMockAuthState()
        
        viewModel.postTitle = "Title"
        viewModel.postContent = String(repeating: "a", count: 5001)
        
        var successCalled = false
        viewModel.createPost(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage?.contains("content exceeds maximum length") == true)
        #expect(successCalled == false)
    }
    
    @Test func testCreatePostWithoutAuthentication() async throws {
        let viewModel = CreatePostViewModel()
        let authState = AuthState(loadPersistedState: false) // Not authenticated
        
        viewModel.postTitle = "Title"
        viewModel.postContent = "Content"
        
        var successCalled = false
        viewModel.createPost(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Not authenticated")
        #expect(successCalled == false)
    }
    
    @Test func testCreatePostSuccess() async throws {
        let viewModel = CreatePostViewModel()
        let authState = createMockAuthState()
        
        viewModel.postTitle = "Great post title"
        viewModel.postContent = "This is awesome content!"
        viewModel.selectedWall = .national
        
        var successCalled = false
        viewModel.createPost(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
    }
    
    // MARK: - Validation Tests
    
    @Test func testTitleTrimming() async throws {
        let viewModel = CreatePostViewModel()
        let authState = createMockAuthState()
        
        viewModel.postTitle = "  Title with spaces  "
        viewModel.postContent = "Content"
        
        viewModel.createPost(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Should accept trimmed title
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testContentTrimming() async throws {
        let viewModel = CreatePostViewModel()
        let authState = createMockAuthState()
        
        viewModel.postTitle = "Title"
        viewModel.postContent = "  Content with spaces  "
        
        viewModel.createPost(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Should accept trimmed content
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testMaxTitleAndContentCount() async throws {
        let viewModel = CreatePostViewModel()
        
        #expect(viewModel.maxTitleCount == 255)
        #expect(viewModel.maxContentCount == 5000)
    }
    
    // MARK: - Wall Selection Tests
    
    @Test func testDefaultWallSelection() async throws {
        let viewModel = CreatePostViewModel()
        
        #expect(viewModel.selectedWall == .campus)
    }
    
    @Test func testWallSelectionChange() async throws {
        let viewModel = CreatePostViewModel()
        
        viewModel.selectedWall = .national
        #expect(viewModel.selectedWall == .national)
        
        viewModel.selectedWall = .campus
        #expect(viewModel.selectedWall == .campus)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testErrorMessageClearedOnNewPost() async throws {
        let viewModel = CreatePostViewModel()
        let authState = createMockAuthState()
        
        // First attempt with empty title
        viewModel.postTitle = ""
        viewModel.postContent = "Content"
        viewModel.createPost(authState: authState) {}
        #expect(viewModel.errorMessage != nil)
        
        // Second attempt with valid data should clear error
        viewModel.postTitle = "Valid Title"
        viewModel.createPost(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.errorMessage == nil)
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
}
