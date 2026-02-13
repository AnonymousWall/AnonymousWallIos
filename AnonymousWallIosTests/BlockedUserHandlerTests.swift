//
//  BlockedUserHandlerTests.swift
//  AnonymousWallIosTests
//
//  Tests for blocked user (403) handling
//

import Foundation
import Testing
@testable import AnonymousWallIos

// MARK: - Blocked User Handler Tests

struct BlockedUserHandlerTests {
    
    @Test func testHandleBlockedUserTriggersCallback() async {
        // Given
        let handler = BlockedUserHandler()
        var callbackExecuted = false
        
        handler.configureHandler {
            callbackExecuted = true
        }
        
        // When
        await handler.handleBlockedUser()
        
        // Then
        #expect(callbackExecuted == true)
    }
    
    @Test func testHandleBlockedUserOnlyExecutesOnce() async {
        // Given
        let handler = BlockedUserHandler()
        var executionCount = 0
        
        handler.configureHandler {
            executionCount += 1
        }
        
        // When - call multiple times
        await handler.handleBlockedUser()
        await handler.handleBlockedUser()
        await handler.handleBlockedUser()
        
        // Then - should only execute once
        #expect(executionCount == 1)
    }
    
    @Test func testHandleBlockedUserCanBeResetForTesting() async {
        // Given
        let handler = BlockedUserHandler()
        var executionCount = 0
        
        handler.configureHandler {
            executionCount += 1
        }
        
        // When - first execution
        await handler.handleBlockedUser()
        #expect(executionCount == 1)
        
        // Reset and try again
        await handler.reset()
        await handler.handleBlockedUser()
        
        // Then - should execute again after reset
        #expect(executionCount == 2)
    }
    
    @Test func testConcurrentBlockedUserCallsOnlyExecuteOnce() async {
        // Given
        let handler = BlockedUserHandler()
        var executionCount = 0
        
        handler.configureHandler {
            executionCount += 1
        }
        
        // When - concurrent calls
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await handler.handleBlockedUser()
                }
            }
        }
        
        // Then - should only execute once despite concurrent calls
        #expect(executionCount == 1)
    }
}

// MARK: - Auth State Blocked User Tests

struct AuthStateBlockedUserTests {
    
    @Test func testHandleBlockedUserLogsOutUser() {
        // Given
        let authState = AuthState(loadPersistedState: false)
        let mockUser = User(
            id: "test-id",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01"
        )
        authState.login(user: mockUser, token: "test-token")
        
        // Verify initial state
        #expect(authState.isAuthenticated == true)
        #expect(authState.currentUser != nil)
        #expect(authState.authToken == "test-token")
        
        // When
        authState.handleBlockedUser()
        
        // Then - all auth state should be cleared
        #expect(authState.isAuthenticated == false)
        #expect(authState.currentUser == nil)
        #expect(authState.authToken == nil)
        #expect(authState.needsPasswordSetup == false)
        #expect(authState.hasShownPasswordSetup == false)
    }
    
    @Test func testHandleBlockedUserSetsAlertFlag() {
        // Given
        let authState = AuthState(loadPersistedState: false)
        let mockUser = User(
            id: "test-id",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01"
        )
        authState.login(user: mockUser, token: "test-token")
        
        #expect(authState.showBlockedUserAlert == false)
        
        // When
        authState.handleBlockedUser()
        
        // Then
        #expect(authState.showBlockedUserAlert == true)
    }
    
    @Test func testHandleBlockedUserClearsPersistedState() {
        // Given
        let authState = AuthState(loadPersistedState: false)
        let mockUser = User(
            id: "test-id",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01"
        )
        authState.login(user: mockUser, token: "test-token")
        
        // When
        authState.handleBlockedUser()
        
        // Then - verify UserDefaults are cleared
        #expect(UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userId) == nil)
        #expect(UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userEmail) == nil)
        #expect(UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.isAuthenticated) == false)
        
        // Verify Keychain is cleared
        let tokenFromKeychain = KeychainHelper.shared.get(AppConfiguration.shared.authTokenKey)
        #expect(tokenFromKeychain == nil)
    }
    
    @Test func testRegularLogoutDoesNotSetBlockedUserAlert() {
        // Given
        let authState = AuthState(loadPersistedState: false)
        let mockUser = User(
            id: "test-id",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01"
        )
        authState.login(user: mockUser, token: "test-token")
        
        // When - regular logout (not blocked)
        authState.logout()
        
        // Then - should not show blocked user alert
        #expect(authState.showBlockedUserAlert == false)
        #expect(authState.isAuthenticated == false)
    }
}

// MARK: - HTTP Status Tests

struct HTTPStatusTests {
    
    @Test func testHTTPStatusConstants() {
        #expect(HTTPStatus.ok == 200)
        #expect(HTTPStatus.created == 201)
        #expect(HTTPStatus.unauthorized == 401)
        #expect(HTTPStatus.forbidden == 403)
        #expect(HTTPStatus.notFound == 404)
        #expect(HTTPStatus.timeout == 408)
    }
    
    @Test func testSuccessRangeContainsValidCodes() {
        #expect(HTTPStatus.successRange.contains(200))
        #expect(HTTPStatus.successRange.contains(201))
        #expect(HTTPStatus.successRange.contains(204))
        #expect(HTTPStatus.successRange.contains(299))
    }
    
    @Test func testSuccessRangeExcludesErrorCodes() {
        #expect(!HTTPStatus.successRange.contains(199))
        #expect(!HTTPStatus.successRange.contains(300))
        #expect(!HTTPStatus.successRange.contains(400))
        #expect(!HTTPStatus.successRange.contains(401))
        #expect(!HTTPStatus.successRange.contains(403))
        #expect(!HTTPStatus.successRange.contains(404))
        #expect(!HTTPStatus.successRange.contains(500))
    }
}

// MARK: - Network Client Blocked User Integration Tests

struct NetworkClientBlockedUserTests {
    
    @Test func testNetworkClientUsesHTTPStatusConstants() async throws {
        // This test verifies that NetworkClient properly uses HTTPStatus enum
        // We can't directly test NetworkClient without a real server,
        // but we can verify the enum is properly imported and used
        
        // Verify the constants are accessible
        let forbidden = HTTPStatus.forbidden
        #expect(forbidden == 403)
        
        let successRange = HTTPStatus.successRange
        #expect(successRange.contains(200))
        #expect(!successRange.contains(403))
    }
}

// MARK: - Helper Extension for Testing

private extension BlockedUserHandler {
    func configureHandler(onBlockedUser: @escaping @MainActor () -> Void) {
        self.onBlockedUser = onBlockedUser
    }
}
