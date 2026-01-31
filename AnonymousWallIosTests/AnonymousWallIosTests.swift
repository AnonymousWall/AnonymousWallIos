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
    }
    
    @Test func testAuthStateLogin() async throws {
        // Test that login updates authentication state
        let authState = AuthState()
        let testUser = User(id: "test-123", email: "test@example.com", createdAt: nil)
        let testToken = "test-token-abc"
        
        authState.login(user: testUser, token: testToken)
        
        #expect(authState.isAuthenticated == true)
        #expect(authState.currentUser?.id == "test-123")
        #expect(authState.currentUser?.email == "test@example.com")
        #expect(authState.authToken == "test-token-abc")
    }
    
    @Test func testAuthStateLogout() async throws {
        // Test that logout clears authentication state
        let authState = AuthState()
        let testUser = User(id: "test-123", email: "test@example.com", createdAt: nil)
        
        // Login first
        authState.login(user: testUser, token: "test-token")
        #expect(authState.isAuthenticated == true)
        
        // Then logout
        authState.logout()
        #expect(authState.isAuthenticated == false)
        #expect(authState.currentUser == nil)
        #expect(authState.authToken == nil)
    }
    
    @Test func testUserModelDecoding() async throws {
        // Test that User model can be decoded from JSON
        let json = """
        {
            "id": "user-456",
            "email": "user@test.com",
            "created_at": "2026-01-31T00:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let user = try decoder.decode(User.self, from: data)
        #expect(user.id == "user-456")
        #expect(user.email == "user@test.com")
        #expect(user.createdAt != nil)
    }
    
    @Test func testAuthResponseDecoding() async throws {
        // Test that AuthResponse can be decoded from JSON
        let json = """
        {
            "success": true,
            "message": "Login successful",
            "user": {
                "id": "user-789",
                "email": "success@test.com"
            },
            "token": "jwt-token-here"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(AuthResponse.self, from: data)
        #expect(response.success == true)
        #expect(response.message == "Login successful")
        #expect(response.user?.id == "user-789")
        #expect(response.token == "jwt-token-here")
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

}

