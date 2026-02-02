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
        #expect(authState.needsPasswordSetup == false) // Should update password status
    }
    
    @Test func testUpdateUserPreservingPasswordStatus() async throws {
        // Test that updateUser can preserve password status when requested
        let authState = AuthState()
        let initialUser = User(id: "test-456", email: "test2@example.com", profileName: "Initial Name", isVerified: true, passwordSet: true, createdAt: "2026-01-31T00:00:00Z")
        
        // Login with password set
        authState.login(user: initialUser, token: "test-token")
        #expect(authState.needsPasswordSetup == false)
        
        // Update user with preservePasswordStatus=true (simulating profile name update)
        let updatedUser = User(id: "test-456", email: "test2@example.com", profileName: "New Name", isVerified: true, passwordSet: false, createdAt: "2026-01-31T00:00:00Z")
        authState.updateUser(updatedUser, preservePasswordStatus: true)
        
        #expect(authState.currentUser?.profileName == "New Name")
        #expect(authState.needsPasswordSetup == false) // Should preserve original status
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
        #expect(post.author.id == "user-123")
        #expect(post.author.profileName == "John Doe")
        #expect(post.author.isAnonymous == true)
    }

}
