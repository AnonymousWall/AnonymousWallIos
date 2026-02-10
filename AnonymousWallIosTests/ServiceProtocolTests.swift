//
//  ServiceProtocolTests.swift
//  AnonymousWallIosTests
//
//  Tests demonstrating protocol-based mocking and dependency injection
//

import Testing
@testable import AnonymousWallIos

// MARK: - Protocol-Based Tests

struct ServiceProtocolTests {
    
    @Test func testMockAuthServiceCanBeUsedInsteadOfRealService() async throws {
        // Demonstrate that mock can replace real service due to protocol conformance
        let mockAuthService: AuthServiceProtocol = MockAuthService()
        
        // Test registration
        let response = try await mockAuthService.registerWithEmail(email: "test@example.com", code: "123456")
        #expect(response.user.email == "test@example.com")
        #expect(response.accessToken == "mock-token")
        
        // Verify mock was called
        if let mock = mockAuthService as? MockAuthService {
            #expect(mock.registerWithEmailCalled == true)
        }
    }
    
    @Test func testMockPostServiceCanBeUsedInsteadOfRealService() async throws {
        // Demonstrate that mock can replace real service due to protocol conformance
        let mockPostService: PostServiceProtocol = MockPostService()
        
        // Test creating post
        let newPost = try await mockPostService.createPost(
            title: "Test Title",
            content: "Test content",
            wall: .campus,
            token: "mock-token",
            userId: "mock-user-id"
        )
        
        #expect(newPost.title == "Test Title")
        #expect(newPost.content == "Test content")
        
        // Verify mock was called
        if let mock = mockPostService as? MockPostService {
            #expect(mock.createPostCalled == true)
            #expect(mock.mockPosts.count == 1)
        }
    }
    
    @Test func testMockAuthServiceCanSimulateLogin() async throws {
        let mockAuthService = MockAuthService()
        
        // Simulate login with email code
        let emailCodeResponse = try await mockAuthService.loginWithEmailCode(email: "user@test.com", code: "123456")
        #expect(emailCodeResponse.user.email == "user@test.com")
        #expect(mockAuthService.loginWithEmailCodeCalled == true)
        
        // Simulate login with password
        let passwordResponse = try await mockAuthService.loginWithPassword(email: "user@test.com", password: "password123")
        #expect(passwordResponse.user.email == "user@test.com")
        #expect(mockAuthService.loginWithPasswordCalled == true)
    }
    
    @Test func testMockPostServiceCanSimulatePostOperations() async throws {
        let mockPostService = MockPostService()
        
        // Fetch posts (initially empty)
        let emptyResponse = try await mockPostService.fetchPosts(
            token: "mock-token",
            userId: "mock-user-id",
            wall: .campus,
            page: 1,
            limit: 20,
            sort: .newest
        )
        #expect(emptyResponse.data.isEmpty)
        #expect(mockPostService.fetchPostsCalled == true)
        
        // Create a post
        _ = try await mockPostService.createPost(
            title: "New Post",
            content: "Content",
            wall: .campus,
            token: "mock-token",
            userId: "mock-user-id"
        )
        
        // Fetch posts again (now has one post)
        let responseWithPost = try await mockPostService.fetchPosts(
            token: "mock-token",
            userId: "mock-user-id",
            wall: .campus,
            page: 1,
            limit: 20,
            sort: .newest
        )
        #expect(responseWithPost.data.count == 1)
        #expect(responseWithPost.data[0].title == "New Post")
    }
    
    @Test func testMockPostServiceCanSimulateReportOperations() async throws {
        let mockPostService = MockPostService()
        
        // Report a post
        let reportPostResponse = try await mockPostService.reportPost(
            postId: "post-1",
            reason: "Inappropriate content",
            token: "mock-token",
            userId: "mock-user-id"
        )
        #expect(reportPostResponse.message == "Post reported successfully")
        #expect(mockPostService.reportPostCalled == true)
        
        // Report a comment
        let reportCommentResponse = try await mockPostService.reportComment(
            postId: "post-1",
            commentId: "comment-1",
            reason: "Spam",
            token: "mock-token",
            userId: "mock-user-id"
        )
        #expect(reportCommentResponse.message == "Comment reported successfully")
        #expect(mockPostService.reportCommentCalled == true)
    }
    
    @Test func testMockServicesEnableDependencyInjection() async throws {
        // Demonstrate that protocols enable dependency injection pattern
        
        // Services can be injected as protocol types
        func performAuthOperation(authService: AuthServiceProtocol) async throws -> String {
            let response = try await authService.loginWithPassword(email: "test@test.com", password: "pass")
            return response.accessToken
        }
        
        func performPostOperation(postService: PostServiceProtocol) async throws -> Int {
            let response = try await postService.fetchPosts(
                token: "token",
                userId: "user",
                wall: .campus,
                page: 1,
                limit: 20,
                sort: .newest
            )
            return response.data.count
        }
        
        // Use mock services
        let mockAuth = MockAuthService()
        let mockPost = MockPostService()
        
        let token = try await performAuthOperation(authService: mockAuth)
        #expect(token == "mock-token")
        
        let postCount = try await performPostOperation(postService: mockPost)
        #expect(postCount == 0)
        
        // Verify mocks were used
        #expect(mockAuth.loginWithPasswordCalled == true)
        #expect(mockPost.fetchPostsCalled == true)
    }
    
    // MARK: - Configurable Mock Behavior Tests
    
    @Test func testMockAuthServiceSuccessScenario() async throws {
        let mockAuthService = MockAuthService()
        
        // Default behavior is success
        let response = try await mockAuthService.loginWithPassword(email: "test@example.com", password: "password")
        #expect(response.accessToken == "mock-token")
        #expect(response.user.email == "test@example.com")
        #expect(mockAuthService.loginWithPasswordCalled == true)
    }
    
    @Test func testMockAuthServiceFailureScenario() async throws {
        let mockAuthService = MockAuthService()
        
        // Configure to fail
        mockAuthService.loginWithPasswordBehavior = .failure(MockAuthService.MockError.invalidCredentials)
        
        do {
            _ = try await mockAuthService.loginWithPassword(email: "test@example.com", password: "wrong")
            Issue.record("Expected error to be thrown")
        } catch let error as MockAuthService.MockError {
            #expect(error == .invalidCredentials)
        }
        
        #expect(mockAuthService.loginWithPasswordCalled == true)
    }
    
    @Test func testMockAuthServiceEmptyStateScenario() async throws {
        let mockAuthService = MockAuthService()
        
        // Configure to return empty state
        mockAuthService.registerWithEmailBehavior = .emptyState
        
        let response = try await mockAuthService.registerWithEmail(email: "test@example.com", code: "123456")
        #expect(response.accessToken == "")
        #expect(response.user.email == "")
        #expect(response.user.profileName == "")
        #expect(mockAuthService.registerWithEmailCalled == true)
    }
    
    @Test func testMockPostServiceSuccessScenario() async throws {
        let mockPostService = MockPostService()
        
        // Add some mock posts
        mockPostService.mockPosts = [
            Post(id: "1", title: "Post 1", content: "Content 1", wall: "CAMPUS", likes: 5, comments: 2, liked: false,
                 author: Post.Author(id: "user1", profileName: "User 1", isAnonymous: true),
                 createdAt: "2026-01-31T00:00:00Z", updatedAt: "2026-01-31T00:00:00Z")
        ]
        
        let response = try await mockPostService.fetchPosts(token: "token", userId: "user", wall: .campus, page: 1, limit: 20, sort: .newest)
        #expect(response.data.count == 1)
        #expect(response.data[0].title == "Post 1")
        #expect(mockPostService.fetchPostsCalled == true)
    }
    
    @Test func testMockPostServiceFailureScenario() async throws {
        let mockPostService = MockPostService()
        
        // Configure to fail
        mockPostService.createPostBehavior = .failure(MockPostService.MockError.unauthorized)
        
        do {
            _ = try await mockPostService.createPost(title: "Test", content: "Content", wall: .campus, token: "token", userId: "user")
            Issue.record("Expected error to be thrown")
        } catch let error as MockPostService.MockError {
            #expect(error == .unauthorized)
        }
        
        #expect(mockPostService.createPostCalled == true)
    }
    
    @Test func testMockPostServiceEmptyStateScenario() async throws {
        let mockPostService = MockPostService()
        
        // Configure to return empty state
        mockPostService.fetchPostsBehavior = .emptyState
        
        let response = try await mockPostService.fetchPosts(token: "token", userId: "user", wall: .campus, page: 1, limit: 20, sort: .newest)
        #expect(response.data.isEmpty)
        #expect(response.pagination.total == 0)
        #expect(mockPostService.fetchPostsCalled == true)
    }
    
    @Test func testMockPostServiceReportSuccessScenario() async throws {
        let mockPostService = MockPostService()
        
        // Default behavior is success
        let postReportResponse = try await mockPostService.reportPost(
            postId: "post-1",
            reason: "Inappropriate",
            token: "token",
            userId: "user"
        )
        #expect(postReportResponse.message == "Post reported successfully")
        #expect(mockPostService.reportPostCalled == true)
        
        let commentReportResponse = try await mockPostService.reportComment(
            postId: "post-1",
            commentId: "comment-1",
            reason: "Spam",
            token: "token",
            userId: "user"
        )
        #expect(commentReportResponse.message == "Comment reported successfully")
        #expect(mockPostService.reportCommentCalled == true)
    }
    
    @Test func testMockPostServiceReportFailureScenario() async throws {
        let mockPostService = MockPostService()
        
        // Configure to fail
        mockPostService.reportPostBehavior = .failure(MockPostService.MockError.unauthorized)
        mockPostService.reportCommentBehavior = .failure(MockPostService.MockError.unauthorized)
        
        do {
            _ = try await mockPostService.reportPost(postId: "post-1", reason: "Test", token: "token", userId: "user")
            Issue.record("Expected error to be thrown")
        } catch let error as MockPostService.MockError {
            #expect(error == .unauthorized)
        }
        #expect(mockPostService.reportPostCalled == true)
        
        do {
            _ = try await mockPostService.reportComment(postId: "post-1", commentId: "comment-1", reason: "Test", token: "token", userId: "user")
            Issue.record("Expected error to be thrown")
        } catch let error as MockPostService.MockError {
            #expect(error == .unauthorized)
        }
        #expect(mockPostService.reportCommentCalled == true)
    }
    
    @Test func testMockPostServiceReportEmptyStateScenario() async throws {
        let mockPostService = MockPostService()
        
        // Configure to return empty state
        mockPostService.reportPostBehavior = .emptyState
        mockPostService.reportCommentBehavior = .emptyState
        
        let postResponse = try await mockPostService.reportPost(postId: "post-1", reason: nil, token: "token", userId: "user")
        #expect(postResponse.message.isEmpty)
        #expect(mockPostService.reportPostCalled == true)
        
        let commentResponse = try await mockPostService.reportComment(postId: "post-1", commentId: "comment-1", reason: nil, token: "token", userId: "user")
        #expect(commentResponse.message.isEmpty)
        #expect(mockPostService.reportCommentCalled == true)
    }
    
    @Test func testMockAuthServiceCustomResponse() async throws {
        let mockAuthService = MockAuthService()
        
        // Configure custom user
        let customUser = User(id: "custom-id", email: "custom@example.com", profileName: "Custom User", isVerified: true, passwordSet: true, createdAt: "2026-02-01T00:00:00Z")
        mockAuthService.mockUser = customUser
        
        let response = try await mockAuthService.loginWithPassword(email: "any@example.com", password: "any")
        #expect(response.user.id == "custom-id")
        #expect(response.user.profileName == "Custom User")
    }
    
    @Test func testMockPostServiceCustomResponse() async throws {
        let mockPostService = MockPostService()
        
        // Configure custom like response
        mockPostService.mockLikeResponse = LikeResponse(liked: true, likeCount: 42)
        
        let response = try await mockPostService.toggleLike(postId: "post-1", token: "token", userId: "user")
        #expect(response.liked == true)
        #expect(response.likeCount == 42)
        #expect(mockPostService.toggleLikeCalled == true)
    }
    
    @Test func testMockAuthServiceResetHelpers() async throws {
        let mockAuthService = MockAuthService()
        
        // Call some methods
        _ = try await mockAuthService.loginWithPassword(email: "test@example.com", password: "password")
        _ = try await mockAuthService.registerWithEmail(email: "test@example.com", code: "123456")
        #expect(mockAuthService.loginWithPasswordCalled == true)
        #expect(mockAuthService.registerWithEmailCalled == true)
        
        // Reset call tracking
        mockAuthService.resetCallTracking()
        #expect(mockAuthService.loginWithPasswordCalled == false)
        #expect(mockAuthService.registerWithEmailCalled == false)
    }
    
    @Test func testMockPostServiceResetHelpers() async throws {
        let mockPostService = MockPostService()
        
        // Add some data
        _ = try await mockPostService.createPost(title: "Test", content: "Content", wall: .campus, token: "token", userId: "user")
        #expect(mockPostService.mockPosts.count == 1)
        #expect(mockPostService.createPostCalled == true)
        
        // Clear mock data
        mockPostService.clearMockData()
        #expect(mockPostService.mockPosts.isEmpty)
        
        // Reset call tracking
        mockPostService.resetCallTracking()
        #expect(mockPostService.createPostCalled == false)
    }
    
    @Test func testMockAuthServiceConfigureAllToFail() async throws {
        let mockAuthService = MockAuthService()
        
        // Configure all methods to fail
        mockAuthService.configureAllToFail(with: MockAuthService.MockError.networkError)
        
        do {
            _ = try await mockAuthService.loginWithPassword(email: "test@example.com", password: "password")
            Issue.record("Expected error to be thrown")
        } catch let error as MockAuthService.MockError {
            #expect(error == .networkError)
        }
        
        do {
            _ = try await mockAuthService.registerWithEmail(email: "test@example.com", code: "123456")
            Issue.record("Expected error to be thrown")
        } catch let error as MockAuthService.MockError {
            #expect(error == .networkError)
        }
    }
    
    @Test func testMockPostServiceConfigureAllToEmptyState() async throws {
        let mockPostService = MockPostService()
        
        // Configure all methods to return empty state
        mockPostService.configureAllToEmptyState()
        
        let postResponse = try await mockPostService.fetchPosts(token: "token", userId: "user", wall: .campus, page: 1, limit: 20, sort: .newest)
        #expect(postResponse.data.isEmpty)
        
        let commentResponse = try await mockPostService.getComments(postId: "post-1", token: "token", userId: "user", page: 1, limit: 20, sort: .newest)
        #expect(commentResponse.data.isEmpty)
    }
    
    // MARK: - UserServiceProtocol Tests
    
    @Test func testMockUserServiceCanBeUsedInsteadOfRealService() async throws {
        // Demonstrate that mock can replace real service due to protocol conformance
        let mockUserService: UserServiceProtocol = MockUserService()
        
        // Test updating profile name
        let updatedUser = try await mockUserService.updateProfileName(
            profileName: "John Doe",
            token: "mock-token",
            userId: "mock-user-id"
        )
        #expect(updatedUser.profileName == "John Doe")
        
        // Verify mock was called
        if let mock = mockUserService as? MockUserService {
            #expect(mock.updateProfileNameCalled == true)
        }
    }
    
    @Test func testMockUserServiceCanSimulateUserOperations() async throws {
        let mockUserService = MockUserService()
        
        // Add some mock data
        mockUserService.mockPosts = [
            Post(id: "1", title: "Post 1", content: "Content 1", wall: "CAMPUS", likes: 5, comments: 2, liked: false,
                 author: Post.Author(id: "user1", profileName: "User 1", isAnonymous: true),
                 createdAt: "2026-02-09T00:00:00Z", updatedAt: "2026-02-09T00:00:00Z")
        ]
        mockUserService.mockComments = [
            Comment(id: "1", postId: "post1", text: "Comment 1",
                    author: Post.Author(id: "user1", profileName: "User 1", isAnonymous: true),
                    createdAt: "2026-02-09T00:00:00Z")
        ]
        
        // Test getting user posts
        let postsResponse = try await mockUserService.getUserPosts(
            token: "token",
            userId: "user",
            page: 1,
            limit: 20,
            sort: .newest
        )
        #expect(postsResponse.data.count == 1)
        #expect(postsResponse.data[0].title == "Post 1")
        #expect(mockUserService.getUserPostsCalled == true)
        
        // Test getting user comments
        let commentsResponse = try await mockUserService.getUserComments(
            token: "token",
            userId: "user",
            page: 1,
            limit: 20,
            sort: .newest
        )
        #expect(commentsResponse.data.count == 1)
        #expect(commentsResponse.data[0].text == "Comment 1")
        #expect(mockUserService.getUserCommentsCalled == true)
    }
    
    @Test func testMockUserServiceSuccessScenario() async throws {
        let mockUserService = MockUserService()
        
        // Default behavior is success
        let user = try await mockUserService.updateProfileName(
            profileName: "Test User",
            token: "token",
            userId: "user-id"
        )
        #expect(user.profileName == "Test User")
        #expect(mockUserService.updateProfileNameCalled == true)
    }
    
    @Test func testMockUserServiceFailureScenario() async throws {
        let mockUserService = MockUserService()
        
        // Configure to fail
        mockUserService.updateProfileNameBehavior = .failure(MockUserService.MockError.unauthorized)
        
        do {
            _ = try await mockUserService.updateProfileName(profileName: "Test", token: "token", userId: "user")
            Issue.record("Expected error to be thrown")
        } catch let error as MockUserService.MockError {
            #expect(error == .unauthorized)
        }
        
        #expect(mockUserService.updateProfileNameCalled == true)
    }
    
    @Test func testMockUserServiceEmptyStateScenario() async throws {
        let mockUserService = MockUserService()
        
        // Configure to return empty state
        mockUserService.getUserPostsBehavior = .emptyState
        
        let response = try await mockUserService.getUserPosts(
            token: "token",
            userId: "user",
            page: 1,
            limit: 20,
            sort: .newest
        )
        #expect(response.data.isEmpty)
        #expect(response.pagination.total == 0)
        #expect(mockUserService.getUserPostsCalled == true)
    }
    
    @Test func testMockUserServiceCustomResponse() async throws {
        let mockUserService = MockUserService()
        
        // Configure custom user
        let customUser = User(
            id: "custom-id",
            email: "custom@example.com",
            profileName: "Custom User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-02-09T00:00:00Z"
        )
        mockUserService.mockUser = customUser
        
        let response = try await mockUserService.updateProfileName(
            profileName: "Any Name",
            token: "any",
            userId: "any"
        )
        #expect(response.id == "custom-id")
        #expect(response.email == "custom@example.com")
    }
    
    @Test func testMockUserServiceResetHelpers() async throws {
        let mockUserService = MockUserService()
        
        // Call some methods
        _ = try await mockUserService.updateProfileName(profileName: "Test", token: "token", userId: "user")
        _ = try await mockUserService.getUserPosts(token: "token", userId: "user", page: 1, limit: 20, sort: .newest)
        #expect(mockUserService.updateProfileNameCalled == true)
        #expect(mockUserService.getUserPostsCalled == true)
        
        // Reset call tracking
        mockUserService.resetCallTracking()
        #expect(mockUserService.updateProfileNameCalled == false)
        #expect(mockUserService.getUserPostsCalled == false)
    }
    
    @Test func testMockUserServiceConfigureAllToFail() async throws {
        let mockUserService = MockUserService()
        
        // Configure all methods to fail
        mockUserService.configureAllToFail(with: MockUserService.MockError.networkError)
        
        do {
            _ = try await mockUserService.updateProfileName(profileName: "Test", token: "token", userId: "user")
            Issue.record("Expected error to be thrown")
        } catch let error as MockUserService.MockError {
            #expect(error == .networkError)
        }
        
        do {
            _ = try await mockUserService.getUserPosts(token: "token", userId: "user", page: 1, limit: 20, sort: .newest)
            Issue.record("Expected error to be thrown")
        } catch let error as MockUserService.MockError {
            #expect(error == .networkError)
        }
    }
    
    @Test func testMockUserServiceConfigureAllToEmptyState() async throws {
        let mockUserService = MockUserService()
        
        // Configure all methods to return empty state
        mockUserService.configureAllToEmptyState()
        
        let postsResponse = try await mockUserService.getUserPosts(token: "token", userId: "user", page: 1, limit: 20, sort: .newest)
        #expect(postsResponse.data.isEmpty)
        
        let commentsResponse = try await mockUserService.getUserComments(token: "token", userId: "user", page: 1, limit: 20, sort: .newest)
        #expect(commentsResponse.data.isEmpty)
        
        let user = try await mockUserService.updateProfileName(profileName: "Test", token: "token", userId: "user")
        #expect(user.profileName == "")
    }
}
