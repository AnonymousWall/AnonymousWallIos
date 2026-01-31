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
        let testUser = User(id: "test-123", email: "test@example.com", isVerified: true, createdAt: "2026-01-31T00:00:00Z")
        let testToken = "test-token-abc"
        
        authState.login(user: testUser, token: testToken, needsPasswordSetup: true)
        
        #expect(authState.isAuthenticated == true)
        #expect(authState.currentUser?.id == "test-123")
        #expect(authState.currentUser?.email == "test@example.com")
        #expect(authState.authToken == "test-token-abc")
        #expect(authState.needsPasswordSetup == true)
    }
    
    @Test func testAuthStateLogout() async throws {
        // Test that logout clears authentication state
        let authState = AuthState()
        let testUser = User(id: "test-123", email: "test@example.com", isVerified: true, createdAt: "2026-01-31T00:00:00Z")
        
        // Login first
        authState.login(user: testUser, token: "test-token", needsPasswordSetup: false)
        #expect(authState.isAuthenticated == true)
        
        // Then logout
        authState.logout()
        #expect(authState.isAuthenticated == false)
        #expect(authState.currentUser == nil)
        #expect(authState.authToken == nil)
        #expect(authState.needsPasswordSetup == false)
    }
    
    @Test func testUserModelDecoding() async throws {
        // Test that User model can be decoded from JSON (new format)
        let json = """
        {
            "id": "user-456",
            "email": "user@test.com",
            "isVerified": true,
            "createdAt": "2026-01-31T00:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let user = try decoder.decode(User.self, from: data)
        #expect(user.id == "user-456")
        #expect(user.email == "user@test.com")
        #expect(user.isVerified == true)
        #expect(user.createdAt == "2026-01-31T00:00:00Z")
    }
    
    @Test func testAuthResponseDecoding() async throws {
        // Test that AuthResponse can be decoded from JSON (new format)
        let json = """
        {
            "accessToken": "jwt-token-here",
            "user": {
                "id": "user-789",
                "email": "success@test.com",
                "isVerified": true,
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
        let testUser = User(id: "test-123", email: "test@example.com", isVerified: true, createdAt: "2026-01-31T00:00:00Z")
        
        // Login with password setup needed
        authState.login(user: testUser, token: "test-token", needsPasswordSetup: true)
        #expect(authState.needsPasswordSetup == true)
        
        // Update password setup status
        authState.updatePasswordSetupStatus(completed: true)
        #expect(authState.needsPasswordSetup == false)
    }

}

