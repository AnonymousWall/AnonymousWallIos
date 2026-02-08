//
//  MockAuthService.swift
//  AnonymousWallIos
//
//  Mock implementation of AuthServiceProtocol for unit testing
//  Provides configurable stub responses for success, failure, and empty states
//

import Foundation

/// Mock AuthService for testing with configurable responses
class MockAuthService: AuthServiceProtocol {
    
    // MARK: - Configuration
    
    /// Configuration for mock behavior
    enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }
    
    /// Default error for failure scenarios
    enum MockError: Error, LocalizedError {
        case invalidCredentials
        case networkError
        case serverError
        case userNotFound
        case invalidCode
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid credentials"
            case .networkError:
                return "Network error"
            case .serverError:
                return "Server error"
            case .userNotFound:
                return "User not found"
            case .invalidCode:
                return "Invalid verification code"
            }
        }
    }
    
    // MARK: - State Tracking
    
    var sendEmailVerificationCodeCalled = false
    var registerWithEmailCalled = false
    var loginWithEmailCodeCalled = false
    var loginWithPasswordCalled = false
    var setPasswordCalled = false
    var changePasswordCalled = false
    var requestPasswordResetCalled = false
    var resetPasswordCalled = false
    var updateProfileNameCalled = false
    
    // MARK: - Configurable Behavior
    
    var sendEmailVerificationCodeBehavior: MockBehavior = .success
    var registerWithEmailBehavior: MockBehavior = .success
    var loginWithEmailCodeBehavior: MockBehavior = .success
    var loginWithPasswordBehavior: MockBehavior = .success
    var setPasswordBehavior: MockBehavior = .success
    var changePasswordBehavior: MockBehavior = .success
    var requestPasswordResetBehavior: MockBehavior = .success
    var resetPasswordBehavior: MockBehavior = .success
    var updateProfileNameBehavior: MockBehavior = .success
    
    // MARK: - Configurable Responses
    
    var mockVerificationCodeResponse: VerificationCodeResponse?
    var mockAuthResponse: AuthResponse?
    var mockUser: User?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Helper Methods for Creating Responses
    
    /// Helper to create VerificationCodeResponse from message string
    private func createVerificationCodeResponse(message: String) -> VerificationCodeResponse {
        let json = """
        "\(message)"
        """
        let data = json.data(using: .utf8)!
        return try! JSONDecoder().decode(VerificationCodeResponse.self, from: data)
    }
    
    // MARK: - Protocol Methods
    
    func sendEmailVerificationCode(email: String, purpose: String) async throws -> VerificationCodeResponse {
        sendEmailVerificationCodeCalled = true
        
        switch sendEmailVerificationCodeBehavior {
        case .success:
            return mockVerificationCodeResponse ?? createVerificationCodeResponse(
                message: "Mock verification code sent to \(email)"
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return createVerificationCodeResponse(message: "")
        }
    }
    
    func registerWithEmail(email: String, code: String) async throws -> AuthResponse {
        registerWithEmailCalled = true
        
        switch registerWithEmailBehavior {
        case .success:
            let user = mockUser ?? User(
                id: "mock-user-id",
                email: email,
                profileName: "Anonymous",
                isVerified: true,
                passwordSet: false,
                createdAt: "2026-01-31T00:00:00Z"
            )
            return mockAuthResponse ?? AuthResponse(accessToken: "mock-token", user: user)
        case .failure(let error):
            throw error
        case .emptyState:
            let emptyUser = User(
                id: "",
                email: "",
                profileName: "",
                isVerified: false,
                passwordSet: false,
                createdAt: ""
            )
            return AuthResponse(accessToken: "", user: emptyUser)
        }
    }
    
    func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse {
        loginWithEmailCodeCalled = true
        
        switch loginWithEmailCodeBehavior {
        case .success:
            let user = mockUser ?? User(
                id: "mock-user-id",
                email: email,
                profileName: "Anonymous",
                isVerified: true,
                passwordSet: true,
                createdAt: "2026-01-31T00:00:00Z"
            )
            return mockAuthResponse ?? AuthResponse(accessToken: "mock-token", user: user)
        case .failure(let error):
            throw error
        case .emptyState:
            let emptyUser = User(
                id: "",
                email: "",
                profileName: "",
                isVerified: false,
                passwordSet: false,
                createdAt: ""
            )
            return AuthResponse(accessToken: "", user: emptyUser)
        }
    }
    
    func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
        loginWithPasswordCalled = true
        
        switch loginWithPasswordBehavior {
        case .success:
            let user = mockUser ?? User(
                id: "mock-user-id",
                email: email,
                profileName: "Anonymous",
                isVerified: true,
                passwordSet: true,
                createdAt: "2026-01-31T00:00:00Z"
            )
            return mockAuthResponse ?? AuthResponse(accessToken: "mock-token", user: user)
        case .failure(let error):
            throw error
        case .emptyState:
            let emptyUser = User(
                id: "",
                email: "",
                profileName: "",
                isVerified: false,
                passwordSet: false,
                createdAt: ""
            )
            return AuthResponse(accessToken: "", user: emptyUser)
        }
    }
    
    func setPassword(password: String, token: String, userId: String) async throws {
        setPasswordCalled = true
        
        switch setPasswordBehavior {
        case .success:
            return
        case .failure(let error):
            throw error
        case .emptyState:
            return
        }
    }
    
    func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws {
        changePasswordCalled = true
        
        switch changePasswordBehavior {
        case .success:
            return
        case .failure(let error):
            throw error
        case .emptyState:
            return
        }
    }
    
    func requestPasswordReset(email: String) async throws {
        requestPasswordResetCalled = true
        
        switch requestPasswordResetBehavior {
        case .success:
            return
        case .failure(let error):
            throw error
        case .emptyState:
            return
        }
    }
    
    func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse {
        resetPasswordCalled = true
        
        switch resetPasswordBehavior {
        case .success:
            let user = mockUser ?? User(
                id: "mock-user-id",
                email: email,
                profileName: "Anonymous",
                isVerified: true,
                passwordSet: true,
                createdAt: "2026-01-31T00:00:00Z"
            )
            return mockAuthResponse ?? AuthResponse(accessToken: "mock-token", user: user)
        case .failure(let error):
            throw error
        case .emptyState:
            let emptyUser = User(
                id: "",
                email: "",
                profileName: "",
                isVerified: false,
                passwordSet: false,
                createdAt: ""
            )
            return AuthResponse(accessToken: "", user: emptyUser)
        }
    }
    
    func updateProfileName(profileName: String, token: String, userId: String) async throws -> User {
        updateProfileNameCalled = true
        
        switch updateProfileNameBehavior {
        case .success:
            return mockUser ?? User(
                id: userId,
                email: "test@example.com",
                profileName: profileName,
                isVerified: true,
                passwordSet: true,
                createdAt: "2026-01-31T00:00:00Z"
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return User(
                id: "",
                email: "",
                profileName: "",
                isVerified: false,
                passwordSet: false,
                createdAt: ""
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset all call tracking flags
    func resetCallTracking() {
        sendEmailVerificationCodeCalled = false
        registerWithEmailCalled = false
        loginWithEmailCodeCalled = false
        loginWithPasswordCalled = false
        setPasswordCalled = false
        changePasswordCalled = false
        requestPasswordResetCalled = false
        resetPasswordCalled = false
        updateProfileNameCalled = false
    }
    
    /// Reset all behaviors to success
    func resetBehaviors() {
        sendEmailVerificationCodeBehavior = .success
        registerWithEmailBehavior = .success
        loginWithEmailCodeBehavior = .success
        loginWithPasswordBehavior = .success
        setPasswordBehavior = .success
        changePasswordBehavior = .success
        requestPasswordResetBehavior = .success
        resetPasswordBehavior = .success
        updateProfileNameBehavior = .success
    }
    
    /// Configure all methods to fail with specific error
    func configureAllToFail(with error: Error) {
        sendEmailVerificationCodeBehavior = .failure(error)
        registerWithEmailBehavior = .failure(error)
        loginWithEmailCodeBehavior = .failure(error)
        loginWithPasswordBehavior = .failure(error)
        setPasswordBehavior = .failure(error)
        changePasswordBehavior = .failure(error)
        requestPasswordResetBehavior = .failure(error)
        resetPasswordBehavior = .failure(error)
        updateProfileNameBehavior = .failure(error)
    }
    
    /// Configure all methods to return empty state
    func configureAllToEmptyState() {
        sendEmailVerificationCodeBehavior = .emptyState
        registerWithEmailBehavior = .emptyState
        loginWithEmailCodeBehavior = .emptyState
        loginWithPasswordBehavior = .emptyState
        setPasswordBehavior = .emptyState
        changePasswordBehavior = .emptyState
        requestPasswordResetBehavior = .emptyState
        resetPasswordBehavior = .emptyState
        updateProfileNameBehavior = .emptyState
    }
}
