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
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        #expect(viewModel.postTitle.isEmpty)
        #expect(viewModel.postContent.isEmpty)
        #expect(viewModel.selectedWall == .campus)
        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Character Count Tests
    
    @Test func testTitleCharacterCount() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = "Test Title"
        #expect(viewModel.titleCharacterCount == 10)
        
        viewModel.postTitle = "A"
        #expect(viewModel.titleCharacterCount == 1)
        
        viewModel.postTitle = ""
        #expect(viewModel.titleCharacterCount == 0)
    }
    
    @Test func testContentCharacterCount() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postContent = "Test Content"
        #expect(viewModel.contentCharacterCount == 12)
        
        viewModel.postContent = "A"
        #expect(viewModel.contentCharacterCount == 1)
        
        viewModel.postContent = ""
        #expect(viewModel.contentCharacterCount == 0)
    }
    
    // MARK: - Length Limit Tests
    
    @Test func testTitleOverLimit() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        // Create a title that's exactly at the limit (255 characters)
        viewModel.postTitle = String(repeating: "a", count: 255)
        #expect(viewModel.isTitleOverLimit == false)
        
        // Create a title that's over the limit (256 characters)
        viewModel.postTitle = String(repeating: "a", count: 256)
        #expect(viewModel.isTitleOverLimit == true)
    }
    
    @Test func testContentOverLimit() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        // Create content that's exactly at the limit (5000 characters)
        viewModel.postContent = String(repeating: "a", count: 5000)
        #expect(viewModel.isContentOverLimit == false)
        
        // Create content that's over the limit (5001 characters)
        viewModel.postContent = String(repeating: "a", count: 5001)
        #expect(viewModel.isContentOverLimit == true)
    }
    
    // MARK: - Button State Tests
    
    @Test func testPostButtonDisabledWhenTitleEmpty() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = ""
        viewModel.postContent = "Some content"
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenTitleWhitespaceOnly() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = "   \n  "
        viewModel.postContent = "Some content"
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenContentEmpty() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = "Title"
        viewModel.postContent = ""
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenContentWhitespaceOnly() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = "Title"
        viewModel.postContent = "   \n  "
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenTitleTooLong() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = String(repeating: "a", count: 256)
        viewModel.postContent = "Content"
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonDisabledWhenContentTooLong() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = "Title"
        viewModel.postContent = String(repeating: "a", count: 5001)
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPostButtonEnabledWhenValid() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = "Valid Title"
        viewModel.postContent = "Valid content"
        
        #expect(viewModel.isPostButtonDisabled == false)
    }
    
    @Test func testPostButtonDisabledWhenLoadingImages() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.postTitle = "Valid Title"
        viewModel.postContent = "Valid content"
        viewModel.isLoadingImages = true
        
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testIsLoadingImagesInitiallyFalse() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        #expect(viewModel.isLoadingImages == false)
    }
    
    @Test func testImageLoadProgressInitiallyZero() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        #expect(viewModel.imageLoadProgress == 0)
    }
    
    // MARK: - Create Post Tests
    
    @Test func testCreatePostWithEmptyTitle() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
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
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
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
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
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
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
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
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
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
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.postTitle = "Great post title"
        viewModel.postContent = "This is awesome content!"
        viewModel.selectedWall = .national
        
        var successCalled = false
        viewModel.createPost(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
    }
    
    // MARK: - Validation Tests
    
    @Test func testTitleTrimming() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.postTitle = "  Title with spaces  "
        viewModel.postContent = "Content"
        
        viewModel.createPost(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should accept trimmed title
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testContentTrimming() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        viewModel.postTitle = "Title"
        viewModel.postContent = "  Content with spaces  "
        
        viewModel.createPost(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Should accept trimmed content
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testMaxTitleAndContentCount() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        #expect(viewModel.maxTitleCount == 255)
        #expect(viewModel.maxContentCount == 5000)
    }
    
    // MARK: - Wall Selection Tests
    
    @Test func testDefaultWallSelection() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        #expect(viewModel.selectedWall == .campus)
    }
    
    @Test func testWallSelectionChange() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        
        viewModel.selectedWall = .national
        #expect(viewModel.selectedWall == .national)
        
        viewModel.selectedWall = .campus
        #expect(viewModel.selectedWall == .campus)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testErrorMessageClearedOnNewPost() async throws {
        let mockPostService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockPostService)
        let authState = createMockAuthState()
        
        // First attempt with empty title
        viewModel.postTitle = ""
        viewModel.postContent = "Content"
        viewModel.createPost(authState: authState) {}
        #expect(viewModel.errorMessage != nil)
        
        // Second attempt with valid data should clear error
        viewModel.postTitle = "Valid Title"
        viewModel.createPost(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Timeout Helper Tests
    
    @Test func testWithTimeoutSucceedsWhenOperationCompletesInTime() async throws {
        let result = try await withTimeout(seconds: 5) {
            "success"
        }
        #expect(result == "success")
    }
    
    @Test func testWithTimeoutThrowsTimeoutErrorWhenOperationExceedsLimit() async throws {
        do {
            _ = try await withTimeout(seconds: 0.1) {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return "should not reach"
            }
            Issue.record("Expected TimeoutError to be thrown")
        } catch is TimeoutError {
            // Expected
        }
    }
    
    @Test func testTimeoutErrorIsError() {
        let error: any Error = TimeoutError()
        #expect(error is TimeoutError)
    }
    
    // MARK: - Poll Mode Tests
    
    @Test func testDefaultPostTypeIsStandard() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        #expect(viewModel.postType == .standard)
        #expect(viewModel.isPollMode == false)
    }
    
    @Test func testSwitchingToPollMode() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        viewModel.postType = .poll
        #expect(viewModel.isPollMode == true)
    }
    
    @Test func testDefaultPollOptionsCount() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        #expect(viewModel.pollOptions.count == 2)
    }
    
    @Test func testCanAddPollOptionWhenFewerThanFour() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        #expect(viewModel.canAddPollOption == true)
        viewModel.addPollOption()
        viewModel.addPollOption()
        #expect(viewModel.pollOptions.count == 4)
        #expect(viewModel.canAddPollOption == false)
    }
    
    @Test func testCanRemovePollOptionWhenMoreThanTwo() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        #expect(viewModel.canRemovePollOption == false)
        viewModel.addPollOption()
        #expect(viewModel.canRemovePollOption == true)
        viewModel.removePollOption(at: 2)
        #expect(viewModel.pollOptions.count == 2)
        #expect(viewModel.canRemovePollOption == false)
    }
    
    @Test func testArePollOptionsValidWithTwoNonEmptyOptions() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        viewModel.pollOptions = ["Option A", "Option B"]
        #expect(viewModel.arePollOptionsValid == true)
    }
    
    @Test func testArePollOptionsInvalidWithEmptyOption() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        viewModel.pollOptions = ["Option A", ""]
        #expect(viewModel.arePollOptionsValid == false)
    }
    
    @Test func testArePollOptionsInvalidWhenOptionExceedsLimit() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        viewModel.pollOptions = ["Option A", String(repeating: "x", count: 101)]
        #expect(viewModel.arePollOptionsValid == false)
    }
    
    @Test func testPollModeButtonDisabledWhenOptionsInvalid() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        viewModel.postType = .poll
        viewModel.postTitle = "A poll"
        viewModel.pollOptions = ["Option A", ""]
        #expect(viewModel.isPostButtonDisabled == true)
    }
    
    @Test func testPollModeButtonEnabledWhenValid() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        viewModel.postType = .poll
        viewModel.postTitle = "A poll"
        viewModel.pollOptions = ["Option A", "Option B"]
        #expect(viewModel.isPostButtonDisabled == false)
    }
    
    @Test func testPollModeContentNotRequired() async throws {
        let viewModel = CreatePostViewModel(postService: MockPostService())
        viewModel.postType = .poll
        viewModel.postTitle = "A poll"
        viewModel.postContent = ""
        viewModel.pollOptions = ["Option A", "Option B"]
        #expect(viewModel.isPostButtonDisabled == false)
    }
    
    @Test func testCreatePollPostSuccess() async throws {
        let mockService = MockPostService()
        let viewModel = CreatePostViewModel(postService: mockService)
        let authState = createMockAuthState()
        
        viewModel.postType = .poll
        viewModel.postTitle = "My Poll"
        viewModel.pollOptions = ["Yes", "No"]
        
        var successCalled = false
        viewModel.createPost(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
        #expect(mockService.createPollPostCalled == true)
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
