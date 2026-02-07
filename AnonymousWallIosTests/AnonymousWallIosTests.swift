//
//  AnonymousWallIosTests.swift
//  AnonymousWallIosTests
//
//  Created by Ziyi Huang on 1/30/26.
//

import Testing
@testable import AnonymousWallIos

struct AnonymousWallIosTests {

    @Test func testAuthStateInitialization() async throws {
        // Test that AuthState initializes with not authenticated
        let authState = AuthState()
        #expect(authState.isAuthenticated == false)
        #expect(authState.currentUser == nil)
        #expect(authState.authToken == nil)
        #expect(authState.needsPasswordSetup == false)
    }
    
    @Test func testAuthStateLogin() async throws {
        // Test that login updates authentication state
        let authState = AuthState()
        let testUser = User(id: "test-123", email: "test@example.com", profileName: "Test User", isVerified: true, passwordSet: false, createdAt: "2026-01-31T00:00:00Z")
        let testToken = "test-token-abc"
        
        authState.login(user: testUser, token: testToken)
        
        #expect(authState.isAuthenticated == true)
        #expect(authState.currentUser?.id == "test-123")
        #expect(authState.currentUser?.email == "test@example.com")
        #expect(authState.currentUser?.profileName == "Test User")
        #expect(authState.authToken == "test-token-abc")
        #expect(authState.needsPasswordSetup == true) // passwordSet is false
    }
    
    @Test func testAuthStateLogout() async throws {
        // Test that logout clears authentication state
        let authState = AuthState()
        let testUser = User(id: "test-123", email: "test@example.com", profileName: "Anonymous", isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
        
        // Login first
        authState.login(user: testUser, token: "test-token")
        #expect(authState.isAuthenticated == true)
        
        // Then logout
        authState.logout()
        #expect(authState.isAuthenticated == false)
        #expect(authState.currentUser == nil)
        #expect(authState.authToken == nil)
        #expect(authState.needsPasswordSetup == false)
    }
    
    @Test func testUserModelDecoding() async throws {
        // Test that User model can be decoded from JSON (new format with profileName)
        let json = """
        {
            "id": "user-456",
            "email": "user@test.com",
            "profileName": "John Doe",
            "isVerified": true,
            "passwordSet": false,
            "createdAt": "2026-01-31T00:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let user = try decoder.decode(User.self, from: data)
        #expect(user.id == "user-456")
        #expect(user.email == "user@test.com")
        #expect(user.profileName == "John Doe")
        #expect(user.isVerified == true)
        #expect(user.passwordSet == false)
        #expect(user.createdAt == "2026-01-31T00:00:00Z")
    }
    
    @Test func testAuthResponseDecoding() async throws {
        // Test that AuthResponse can be decoded from JSON (new format with profileName)
        let json = """
        {
            "accessToken": "jwt-token-here",
            "user": {
                "id": "user-789",
                "email": "success@test.com",
                "profileName": "Anonymous",
                "isVerified": true,
                "passwordSet": true,
                "createdAt": "2026-01-31T00:00:00Z"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(AuthResponse.self, from: data)
        #expect(response.accessToken == "jwt-token-here")
        #expect(response.user.id == "user-789")
        #expect(response.user.email == "success@test.com")
        #expect(response.user.profileName == "Anonymous")
    }
    
    @Test func testEmailValidation() async throws {
        // Test valid emails
        #expect(ValidationUtils.isValidEmail("test@example.com") == true)
        #expect(ValidationUtils.isValidEmail("user.name@domain.co.uk") == true)
        #expect(ValidationUtils.isValidEmail("user+tag@example.org") == true)
        
        // Test invalid emails
        #expect(ValidationUtils.isValidEmail("invalid") == false)
        #expect(ValidationUtils.isValidEmail("@example.com") == false)
        #expect(ValidationUtils.isValidEmail("user@") == false)
        #expect(ValidationUtils.isValidEmail("") == false)
    }
    
    @Test func testKeychainHelper() async throws {
        // Test saving and retrieving from keychain
        let testKey = "test.key.unique"
        let testValue = "test-value-123"
        
        // Clean up first
        KeychainHelper.shared.delete(testKey)
        
        // Test save
        let saveResult = KeychainHelper.shared.save(testValue, forKey: testKey)
        #expect(saveResult == true)
        
        // Test retrieve
        let retrievedValue = KeychainHelper.shared.get(testKey)
        #expect(retrievedValue == testValue)
        
        // Test delete
        let deleteResult = KeychainHelper.shared.delete(testKey)
        #expect(deleteResult == true)
        
        // Verify deleted
        let afterDelete = KeychainHelper.shared.get(testKey)
        #expect(afterDelete == nil)
    }
    
    @Test func testPasswordSetupStatus() async throws {
        // Test password setup status update
        let authState = AuthState()
        let testUser = User(id: "test-123", email: "test@example.com", profileName: "Test User", isVerified: true, passwordSet: false, createdAt: "2026-01-31T00:00:00Z")
        
        // Login with password setup needed (passwordSet is false)
        authState.login(user: testUser, token: "test-token")
        #expect(authState.needsPasswordSetup == true)
        
        // Update password setup status
        authState.updatePasswordSetupStatus(completed: true)
        #expect(authState.needsPasswordSetup == false)
    }
    
    @Test func testNetworkErrorDescriptions() async throws {
        // Test that all NetworkError cases have error descriptions
        #expect(NetworkError.invalidURL.errorDescription == "Invalid URL")
        #expect(NetworkError.invalidResponse.errorDescription == "Invalid response from server")
        #expect(NetworkError.unauthorized.errorDescription == "Unauthorized - please login again")
        #expect(NetworkError.forbidden.errorDescription == "Access forbidden")
        #expect(NetworkError.notFound.errorDescription == "Resource not found")
        #expect(NetworkError.timeout.errorDescription == "Request timeout")
        #expect(NetworkError.noConnection.errorDescription == "No internet connection")
        #expect(NetworkError.cancelled.errorDescription == "Request cancelled")
    }
    
    // MARK: - Comment Model Tests
    
    @Test func testCommentDecoding() async throws {
        // Test that Comment model can be decoded from JSON
        let json = """
        {
            "id": "comment-123",
            "postId": "post-456",
            "text": "This is a test comment",
            "author": {
                "id": "user-789",
                "profileName": "Test User",
                "isAnonymous": true
            },
            "createdAt": "2026-01-31T12:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let comment = try decoder.decode(Comment.self, from: data)
        #expect(comment.id == "comment-123")
        #expect(comment.postId == "post-456")
        #expect(comment.text == "This is a test comment")
        #expect(comment.author.id == "user-789")
        #expect(comment.author.profileName == "Test User")
        #expect(comment.author.isAnonymous == true)
        #expect(comment.createdAt == "2026-01-31T12:00:00Z")
    }
    
    @Test func testCommentListResponseDecoding() async throws {
        // Test that CommentListResponse can be decoded from JSON
        let json = """
        {
            "data": [
                {
                    "id": "comment-1",
                    "postId": "post-1",
                    "text": "First comment",
                    "author": {
                        "id": "user-1",
                        "profileName": "User One",
                        "isAnonymous": true
                    },
                    "createdAt": "2026-01-31T10:00:00Z"
                },
                {
                    "id": "comment-2",
                    "postId": "post-1",
                    "text": "Second comment",
                    "author": {
                        "id": "user-2",
                        "profileName": "Anonymous",
                        "isAnonymous": true
                    },
                    "createdAt": "2026-01-31T11:00:00Z"
                }
            ],
            "pagination": {
                "page": 1,
                "limit": 20,
                "total": 2,
                "totalPages": 1
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(CommentListResponse.self, from: data)
        #expect(response.data.count == 2)
        #expect(response.data[0].id == "comment-1")
        #expect(response.data[0].text == "First comment")
        #expect(response.data[0].author.profileName == "User One")
        #expect(response.data[1].id == "comment-2")
        #expect(response.data[1].text == "Second comment")
        #expect(response.data[1].author.profileName == "Anonymous")
        #expect(response.pagination.page == 1)
        #expect(response.pagination.total == 2)
    }
    
    @Test func testCreateCommentRequestEncoding() async throws {
        // Test that CreateCommentRequest can be encoded to JSON
        let request = CreateCommentRequest(text: "New test comment")
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"text\""))
        #expect(json.contains("New test comment"))
    }
    
    @Test func testHidePostResponseDecoding() async throws {
        // Test that HidePostResponse can be decoded (used for hide comment too)
        let json = """
        {
            "message": "Comment hidden successfully"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(HidePostResponse.self, from: data)
        #expect(response.message == "Comment hidden successfully")
    }
    
    // MARK: - SortOrder Tests
    
    @Test func testSortOrderDisplayNames() async throws {
        // Test that all sort orders have correct display names
        #expect(SortOrder.newest.displayName == "Recent")
        #expect(SortOrder.oldest.displayName == "Oldest")
        #expect(SortOrder.mostLiked.displayName == "Most Likes")
        #expect(SortOrder.leastLiked.displayName == "Least Likes")
    }
    
    @Test func testSortOrderFeedOptions() async throws {
        // Test that feed options contain the correct sort orders
        let feedOptions = SortOrder.feedOptions
        #expect(feedOptions.count == 3)
        #expect(feedOptions.contains(.newest))
        #expect(feedOptions.contains(.mostLiked))
        #expect(feedOptions.contains(.oldest))
        #expect(!feedOptions.contains(.leastLiked)) // Should not be included
    }
    
    @Test func testSortOrderRawValues() async throws {
        // Test that sort order raw values match backend API expectations
        #expect(SortOrder.newest.rawValue == "NEWEST")
        #expect(SortOrder.oldest.rawValue == "OLDEST")
        #expect(SortOrder.mostLiked.rawValue == "MOST_LIKED")
        #expect(SortOrder.leastLiked.rawValue == "LEAST_LIKED")
    }
    
    // MARK: - Profile Name Tests
    
    @Test func testUpdateUserMethod() async throws {
        // Test that updateUser updates the current user and persists changes
        let authState = AuthState()
        let initialUser = User(id: "test-123", email: "test@example.com", profileName: "Anonymous", isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
        
        // Login first
        authState.login(user: initialUser, token: "test-token")
        #expect(authState.currentUser?.profileName == "Anonymous")
        #expect(authState.needsPasswordSetup == false)
        
        // Update user with new profile name
        let updatedUser = User(id: "test-123", email: "test@example.com", profileName: "John Doe", isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
        authState.updateUser(updatedUser)
        
        #expect(authState.currentUser?.profileName == "John Doe")
        #expect(authState.currentUser?.id == "test-123")
        #expect(authState.currentUser?.email == "test@example.com")
        #expect(authState.needsPasswordSetup == false) // Verify password status is updated from API
    }
    
    @Test func testUserWithProfileName() async throws {
        // Test that User model with profileName can be properly initialized
        let user = User(id: "user-123", email: "user@example.com", profileName: "Test Name", isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
        
        #expect(user.id == "user-123")
        #expect(user.email == "user@example.com")
        #expect(user.profileName == "Test Name")
        #expect(user.isVerified == true)
        #expect(user.passwordSet == true)
    }
    
    @Test func testUserWithAnonymousProfileName() async throws {
        // Test that default profile name is properly handled
        let user = User(id: "user-456", email: "user2@example.com", profileName: "Anonymous", isVerified: true, passwordSet: false, createdAt: "2026-01-31T00:00:00Z")
        
        #expect(user.profileName == "Anonymous")
    }
    
    @Test func testPostAuthorWithProfileName() async throws {
        // Test that Post.Author includes profileName
        let json = """
        {
            "id": "1",
            "title": "Test Post Title",
            "content": "Test post content",
            "wall": "CAMPUS",
            "likes": 5,
            "comments": 2,
            "liked": false,
            "author": {
                "id": "user-123",
                "profileName": "John Doe",
                "isAnonymous": true
            },
            "createdAt": "2026-01-31T12:00:00Z",
            "updatedAt": "2026-01-31T12:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let post = try decoder.decode(Post.self, from: data)
        #expect(post.id == "1")
        #expect(post.title == "Test Post Title")
        #expect(post.content == "Test post content")
        #expect(post.author.id == "user-123")
        #expect(post.author.profileName == "John Doe")
        #expect(post.author.isAnonymous == true)
    }
    
    @Test func testCreatePostRequestEncoding() async throws {
        // Test that CreatePostRequest includes title field
        let request = CreatePostRequest(title: "Test Title", content: "Test content", wall: "campus")
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        #expect(json.contains("\"title\""))
        #expect(json.contains("Test Title"))
        #expect(json.contains("\"content\""))
        #expect(json.contains("Test content"))
        #expect(json.contains("\"wall\""))
        #expect(json.contains("campus"))
    }
    
    // MARK: - ProfileView Sorting Tests
    
    @Test func testProfilePostSortingByNewest() async throws {
        // Test that posts can be sorted by newest
        let posts = [
            Post(id: "1", title: "First", content: "First post", wall: "CAMPUS", likes: 5, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-01T10:00:00Z", updatedAt: "2026-01-01T10:00:00Z"),
            Post(id: "2", title: "Second", content: "Second post", wall: "CAMPUS", likes: 3, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-02T10:00:00Z", updatedAt: "2026-01-02T10:00:00Z"),
            Post(id: "3", title: "Third", content: "Third post", wall: "CAMPUS", likes: 10, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-01T15:00:00Z", updatedAt: "2026-01-01T15:00:00Z")
        ]
        
        let sorted = posts.sorted { $0.createdAt > $1.createdAt }
        #expect(sorted[0].id == "2") // Most recent
        #expect(sorted[1].id == "3")
        #expect(sorted[2].id == "1") // Oldest
    }
    
    @Test func testProfilePostSortingByOldest() async throws {
        // Test that posts can be sorted by oldest
        let posts = [
            Post(id: "1", title: "First", content: "First post", wall: "CAMPUS", likes: 5, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-01T10:00:00Z", updatedAt: "2026-01-01T10:00:00Z"),
            Post(id: "2", title: "Second", content: "Second post", wall: "CAMPUS", likes: 3, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-02T10:00:00Z", updatedAt: "2026-01-02T10:00:00Z"),
            Post(id: "3", title: "Third", content: "Third post", wall: "CAMPUS", likes: 10, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-01T15:00:00Z", updatedAt: "2026-01-01T15:00:00Z")
        ]
        
        let sorted = posts.sorted { $0.createdAt < $1.createdAt }
        #expect(sorted[0].id == "1") // Oldest
        #expect(sorted[1].id == "3")
        #expect(sorted[2].id == "2") // Most recent
    }
    
    @Test func testProfilePostSortingByMostLiked() async throws {
        // Test that posts can be sorted by most liked
        let posts = [
            Post(id: "1", title: "First", content: "First post", wall: "CAMPUS", likes: 5, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-01T10:00:00Z", updatedAt: "2026-01-01T10:00:00Z"),
            Post(id: "2", title: "Second", content: "Second post", wall: "CAMPUS", likes: 3, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-02T10:00:00Z", updatedAt: "2026-01-02T10:00:00Z"),
            Post(id: "3", title: "Third", content: "Third post", wall: "CAMPUS", likes: 10, comments: 0, liked: false,
                 author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                 createdAt: "2026-01-01T15:00:00Z", updatedAt: "2026-01-01T15:00:00Z")
        ]
        
        let sorted = posts.sorted { $0.likes > $1.likes }
        #expect(sorted[0].id == "3") // Most likes (10)
        #expect(sorted[1].id == "1") // 5 likes
        #expect(sorted[2].id == "2") // Least likes (3)
    }
    
    @Test func testProfileCommentSortingByNewest() async throws {
        // Test that comments can be sorted by newest
        let comments = [
            Comment(id: "1", postId: "post1", text: "First comment",
                    author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                    createdAt: "2026-01-01T10:00:00Z"),
            Comment(id: "2", postId: "post1", text: "Second comment",
                    author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                    createdAt: "2026-01-02T10:00:00Z"),
            Comment(id: "3", postId: "post1", text: "Third comment",
                    author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                    createdAt: "2026-01-01T15:00:00Z")
        ]
        
        let sorted = comments.sorted { $0.createdAt > $1.createdAt }
        #expect(sorted[0].id == "2") // Most recent
        #expect(sorted[1].id == "3")
        #expect(sorted[2].id == "1") // Oldest
    }
    
    @Test func testProfileCommentSortingByOldest() async throws {
        // Test that comments can be sorted by oldest
        let comments = [
            Comment(id: "1", postId: "post1", text: "First comment",
                    author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                    createdAt: "2026-01-01T10:00:00Z"),
            Comment(id: "2", postId: "post1", text: "Second comment",
                    author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                    createdAt: "2026-01-02T10:00:00Z"),
            Comment(id: "3", postId: "post1", text: "Third comment",
                    author: Post.Author(id: "user1", profileName: "User", isAnonymous: true),
                    createdAt: "2026-01-01T15:00:00Z")
        ]
        
        let sorted = comments.sorted { $0.createdAt < $1.createdAt }
        #expect(sorted[0].id == "1") // Oldest
        #expect(sorted[1].id == "3")
        #expect(sorted[2].id == "2") // Most recent
    }
    
    // MARK: - Post Like Tests
    
    @Test func testPostWithUpdatedLike() async throws {
        // Test that Post.withUpdatedLike creates a new post with updated like status
        let originalPost = Post(
            id: "1",
            title: "Test Post",
            content: "Test content",
            wall: "CAMPUS",
            likes: 5,
            comments: 2,
            liked: false,
            author: Post.Author(id: "user-123", profileName: "Test User", isAnonymous: true),
            createdAt: "2026-01-31T12:00:00Z",
            updatedAt: "2026-01-31T12:00:00Z"
        )
        
        // Test liking the post
        let likedPost = originalPost.withUpdatedLike(liked: true, likes: 6)
        #expect(likedPost.id == originalPost.id)
        #expect(likedPost.title == originalPost.title)
        #expect(likedPost.content == originalPost.content)
        #expect(likedPost.liked == true)
        #expect(likedPost.likes == 6)
        #expect(likedPost.comments == originalPost.comments)
        
        // Test unliking the post
        let unlikedPost = likedPost.withUpdatedLike(liked: false, likes: 5)
        #expect(unlikedPost.liked == false)
        #expect(unlikedPost.likes == 5)
    }
    
    @Test func testPostLikedStateFromAPI() async throws {
        // Test that Post model correctly decodes liked state from API
        let likedPostJson = """
        {
            "id": "1",
            "title": "Liked Post",
            "content": "This post is liked",
            "wall": "CAMPUS",
            "likes": 10,
            "comments": 5,
            "liked": true,
            "author": {
                "id": "user-123",
                "profileName": "Test User",
                "isAnonymous": true
            },
            "createdAt": "2026-01-31T12:00:00Z",
            "updatedAt": "2026-01-31T12:00:00Z"
        }
        """
        
        let unlikedPostJson = """
        {
            "id": "2",
            "title": "Not Liked Post",
            "content": "This post is not liked",
            "wall": "CAMPUS",
            "likes": 3,
            "comments": 1,
            "liked": false,
            "author": {
                "id": "user-456",
                "profileName": "Another User",
                "isAnonymous": true
            },
            "createdAt": "2026-01-31T13:00:00Z",
            "updatedAt": "2026-01-31T13:00:00Z"
        }
        """
        
        let decoder = JSONDecoder()
        
        let likedPost = try decoder.decode(Post.self, from: likedPostJson.data(using: .utf8)!)
        #expect(likedPost.liked == true)
        #expect(likedPost.likes == 10)
        
        let unlikedPost = try decoder.decode(Post.self, from: unlikedPostJson.data(using: .utf8)!)
        #expect(unlikedPost.liked == false)
        #expect(unlikedPost.likes == 3)
    }
    
    @Test func testLikeResponseDecoding() async throws {
        // Test that LikeResponse can be decoded from API
        let likedJson = """
        {
            "liked": true
        }
        """
        
        let unlikedJson = """
        {
            "liked": false
        }
        """
        
        let decoder = JSONDecoder()
        
        let likedResponse = try decoder.decode(LikeResponse.self, from: likedJson.data(using: .utf8)!)
        #expect(likedResponse.liked == true)
        
        let unlikedResponse = try decoder.decode(LikeResponse.self, from: unlikedJson.data(using: .utf8)!)
        #expect(unlikedResponse.liked == false)
    }

}
