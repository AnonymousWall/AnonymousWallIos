//
//  RefreshTokenTests.swift
//  AnonymousWallIosTests
//
//  Tests for refresh token storage, logout, and AuthState behaviour
//

import Testing
@testable import AnonymousWallIos
import Foundation

// MARK: - TokenRefreshResponse Tests

struct TokenRefreshResponseTests {

    @Test func testTokenRefreshResponseDecoding() throws {
        let json = """
        {"accessToken":"new-access","refreshToken":"new-refresh"}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(TokenRefreshResponse.self, from: json)
        #expect(decoded.accessToken == "new-access")
        #expect(decoded.refreshToken == "new-refresh")
    }
}

// MARK: - AuthResponse refreshToken Tests

struct AuthResponseRefreshTokenTests {

    @Test func testAuthResponseWithRefreshToken() throws {
        let userJson = """
        {
          "id":"u1","email":"a@b.com","profileName":"Anon",
          "isVerified":true,"passwordSet":true,"createdAt":"2026-01-01T00:00:00Z"
        }
        """
        let json = """
        {"accessToken":"access","refreshToken":"refresh","user":\(userJson)}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AuthResponse.self, from: json)
        #expect(decoded.accessToken == "access")
        #expect(decoded.refreshToken == "refresh")
        #expect(decoded.user.id == "u1")
    }

    @Test func testAuthResponseWithoutRefreshTokenIsNil() throws {
        let userJson = """
        {
          "id":"u1","email":"a@b.com","profileName":"Anon",
          "isVerified":true,"passwordSet":true,"createdAt":"2026-01-01T00:00:00Z"
        }
        """
        // Legacy response without refreshToken field
        let json = """
        {"accessToken":"access","user":\(userJson)}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AuthResponse.self, from: json)
        #expect(decoded.refreshToken == nil)
    }
}

// MARK: - AppConfiguration refreshTokenKey Tests

struct AppConfigurationRefreshTokenKeyTests {

    @Test func testRefreshTokenKeyIsDistinctFromAuthTokenKey() {
        let config = AppConfiguration.shared
        #expect(config.refreshTokenKey != config.authTokenKey)
    }

    @Test func testRefreshTokenKeyContainsService() {
        let config = AppConfiguration.shared
        #expect(config.refreshTokenKey.contains(config.keychainService))
    }
}

// MARK: - AuthState Refresh Token Tests

@MainActor
struct AuthStateRefreshTokenTests {

    private func makeUser() -> User {
        User(id: "u1", email: "a@b.com", profileName: "Anon",
             isVerified: true, passwordSet: true, createdAt: "2026-01-01T00:00:00Z")
    }

    @Test func testLoginWithRefreshTokenSavesToKeychain() {
        let authState = AuthState(loadPersistedState: false)
        let config = AppConfiguration.shared

        // Ensure clean slate
        KeychainHelper.shared.delete(config.refreshTokenKey)

        authState.login(user: makeUser(), token: "access-token", refreshToken: "refresh-token")

        let stored = KeychainHelper.shared.get(config.refreshTokenKey)
        #expect(stored == "refresh-token")

        // Clean up
        KeychainHelper.shared.delete(config.refreshTokenKey)
        KeychainHelper.shared.delete(config.authTokenKey)
    }

    @Test func testLoginWithoutRefreshTokenDoesNotOverwriteKeychain() {
        let authState = AuthState(loadPersistedState: false)
        let config = AppConfiguration.shared

        // Pre-seed a refresh token
        KeychainHelper.shared.save("existing-refresh", forKey: config.refreshTokenKey)

        // Login without providing a refreshToken
        authState.login(user: makeUser(), token: "new-access-token")

        // The pre-existing refresh token should remain untouched
        let stored = KeychainHelper.shared.get(config.refreshTokenKey)
        #expect(stored == "existing-refresh")

        // Clean up
        KeychainHelper.shared.delete(config.refreshTokenKey)
        KeychainHelper.shared.delete(config.authTokenKey)
    }

    @Test func testLogoutClearsRefreshTokenFromKeychain() async throws {
        let authState = AuthState(loadPersistedState: false)
        let config = AppConfiguration.shared

        // Seed tokens so logout has something to delete
        KeychainHelper.shared.save("access-token", forKey: config.authTokenKey)
        KeychainHelper.shared.save("refresh-token", forKey: config.refreshTokenKey)

        authState.login(user: makeUser(), token: "access-token", refreshToken: "refresh-token")
        authState.logout()

        // Give async clearAuthState() a moment to run
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(KeychainHelper.shared.get(config.refreshTokenKey) == nil)
        #expect(KeychainHelper.shared.get(config.authTokenKey) == nil)
    }

    @Test func testLogoutClearsInMemoryState() {
        let authState = AuthState(loadPersistedState: false)
        authState.login(user: makeUser(), token: "access-token", refreshToken: "refresh-token")

        authState.logout()

        #expect(authState.isAuthenticated == false)
        #expect(authState.currentUser == nil)
        #expect(authState.authToken == nil)
        #expect(authState.needsPasswordSetup == false)
    }
}

// MARK: - MockAuthService logout Tests

struct MockAuthServiceLogoutTests {

    @Test func testMockAuthServiceLogoutSuccess() async throws {
        let mock = MockAuthService()
        mock.logoutBehavior = .success
        try await mock.logout(token: "tok", userId: "uid")
        #expect(mock.logoutCalled == true)
    }

    @Test func testMockAuthServiceLogoutFailure() async {
        let mock = MockAuthService()
        mock.logoutBehavior = .failure(NetworkError.serverError("oops"))
        do {
            try await mock.logout(token: "tok", userId: "uid")
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(mock.logoutCalled == true)
        }
    }

    @Test func testResetCallTrackingClearsLogoutFlag() async throws {
        let mock = MockAuthService()
        try await mock.logout(token: "tok", userId: "uid")
        mock.resetCallTracking()
        #expect(mock.logoutCalled == false)
    }
}
