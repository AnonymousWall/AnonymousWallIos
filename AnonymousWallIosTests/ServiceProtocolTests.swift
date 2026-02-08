//
//  ServiceProtocolTests.swift
//  AnonymousWallIosTests
//
//  Tests demonstrating protocol-based mocking and dependency injection
//

import Testing
@testable import AnonymousWallIos

// MARK: - Mock Service Implementations

/// Mock AuthService for testing
class MockAuthService: AuthServiceProtocol {
    var sendEmailVerificationCodeCalled = false
    var registerWithEmailCalled = false
    var loginWithEmailCodeCalled = false
    var loginWithPasswordCalled = false
    var setPasswordCalled = false
    
    func sendEmailVerificationCode(email: String, purpose: String) async throws -> VerificationCodeResponse {
        sendEmailVerificationCodeCalled = true
        return VerificationCodeResponse(message: "Mock verification code sent")
    }
    
    func registerWithEmail(email: String, code: String) async throws -> AuthResponse {
        registerWithEmailCalled = true
        let mockUser = User(id: "mock-user-id", email: email, profileName: "Anonymous", isVerified: true, passwordSet: false, createdAt: "2026-01-31T00:00:00Z")
        return AuthResponse(accessToken: "mock-token", user: mockUser)
    }
    
    func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse {
        loginWithEmailCodeCalled = true
        let mockUser = User(id: "mock-user-id", email: email, profileName: "Anonymous", isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
        return AuthResponse(accessToken: "mock-token", user: mockUser)
    }
    
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
        loginWithPasswordCalled = true
        let mockUser = User(id: "mock-user-id", email: email, profileName: "Anonymous", isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
        return AuthResponse(accessToken: "mock-token", user: mockUser)
    }
    
    func setPassword(password: String, token: String, userId: String) async throws {
        setPasswordCalled = true
    }
    
    func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws {
        // Mock implementation
    }
    
    func requestPasswordReset(email: String) async throws {
        // Mock implementation
    }
    
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse {
        let mockUser = User(id: "mock-user-id", email: email, profileName: "Anonymous", isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
        return AuthResponse(accessToken: "mock-token", user: mockUser)
    }
    
    func updateProfileName(profileName: String, token: String, userId: String) async throws -> User {
        return User(id: userId, email: "test@example.com", profileName: profileName, isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
    }
}

/// Mock PostService for testing
class MockPostService: PostServiceProtocol {
    var fetchPostsCalled = false
    var createPostCalled = false
    var toggleLikeCalled = false
    var mockPosts: [Post] = []
    
    func fetchPosts(token: String, userId: String, wall: WallType, page: Int, limit: Int, sort: SortOrder) async throws -> PostListResponse {
        fetchPostsCalled = true
        return PostListResponse(
            data: mockPosts,
            pagination: PaginationInfo(page: page, limit: limit, total: mockPosts.count, totalPages: 1)
        )
    }
    
    func getPost(postId: String, token: String, userId: String) async throws -> Post {
        return Post(id: postId, title: "Mock Post", content: "Mock content", wall: "CAMPUS", likes: 0, comments: 0, liked: false,
                   author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: true),
                   createdAt: "2026-01-31T00:00:00Z", updatedAt: "2026-01-31T00:00:00Z")
    }
    
    func createPost(title: String, content: String, wall: WallType, token: String, userId: String) async throws -> Post {
        createPostCalled = true
        let newPost = Post(id: "new-post-id", title: title, content: content, wall: wall.rawValue, likes: 0, comments: 0, liked: false,
                          author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: true),
                          createdAt: "2026-01-31T00:00:00Z", updatedAt: "2026-01-31T00:00:00Z")
        mockPosts.append(newPost)
        return newPost
    }
    
    func toggleLike(postId: String, token: String, userId: String) async throws -> LikeResponse {
        toggleLikeCalled = true
        return LikeResponse(liked: true, likeCount: 1)
    }
    
    func hidePost(postId: String, token: String, userId: String) async throws -> HidePostResponse {
        return HidePostResponse(message: "Post hidden successfully")
    }
    
    func addComment(postId: String, text: String, token: String, userId: String) async throws -> Comment {
        return Comment(id: "new-comment-id", postId: postId, text: text,
                      author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: true),
                      createdAt: "2026-01-31T00:00:00Z")
    }
    
    func getComments(postId: String, token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> CommentListResponse {
        return CommentListResponse(
            data: [],
            pagination: PaginationInfo(page: page, limit: limit, total: 0, totalPages: 0)
        )
    }
    
    func hideComment(postId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        return HidePostResponse(message: "Comment hidden successfully")
    }
    
    func getUserComments(token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> CommentListResponse {
        return CommentListResponse(
            data: [],
            pagination: PaginationInfo(page: page, limit: limit, total: 0, totalPages: 0)
        )
    }
    
    func getUserPosts(token: String, userId: String, page: Int, limit: Int, sort: SortOrder) async throws -> PostListResponse {
        return PostListResponse(
            data: [],
            pagination: PaginationInfo(page: page, limit: limit, total: 0, totalPages: 0)
        )
    }
}

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
}
