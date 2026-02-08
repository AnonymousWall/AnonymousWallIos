//
//  MockAuthService.swift
//  AnonymousWallIos
//
//  Mock implementation of AuthServiceProtocol for unit testing
//  Provides configurable stub responses for success, failure, and empty states
//

import Foundation

/// Mock AuthService for testing with configurable responses
public class MockAuthService: AuthServiceProtocol {
    
    // MARK: - Configuration
    
    /// Configuration for mock behavior
    public enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }
    
    /// Default error for failure scenarios
    public enum MockError: Error, LocalizedError {
        case invalidCredentials
        case networkError
        case serverError
        case userNotFound
        case invalidCode
        
        public var errorDescription: String? {
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
    
    public var sendEmailVerificationCodeCalled = false
    public var registerWithEmailCalled = false
    public var loginWithEmailCodeCalled = false
    public var loginWithPasswordCalled = false
    public var setPasswordCalled = false
    public var changePasswordCalled = false
    public var requestPasswordResetCalled = false
    public var resetPasswordCalled = false
    public var updateProfileNameCalled = false
    
    // MARK: - Configurable Behavior
    
    public var sendEmailVerificationCodeBehavior: MockBehavior = .success
    public var registerWithEmailBehavior: MockBehavior = .success
    public var loginWithEmailCodeBehavior: MockBehavior = .success
    public var loginWithPasswordBehavior: MockBehavior = .success
    public var setPasswordBehavior: MockBehavior = .success
    public var changePasswordBehavior: MockBehavior = .success
    public var requestPasswordResetBehavior: MockBehavior = .success
    public var resetPasswordBehavior: MockBehavior = .success
    public var updateProfileNameBehavior: MockBehavior = .success
    
    // MARK: - Configurable Responses
    
    public var mockVerificationCodeResponse: VerificationCodeResponse?
    public var mockAuthResponse: AuthResponse?
    public var mockUser: User?
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Protocol Methods
    
    public func sendEmailVerificationCode(email: String, purpose: String) async throws -> VerificationCodeResponse {
        sendEmailVerificationCodeCalled = true
        
        switch sendEmailVerificationCodeBehavior {
        case .success:
            return mockVerificationCodeResponse ?? VerificationCodeResponse(
                message: "Mock verification code sent to \(email)"
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return VerificationCodeResponse(message: "")
        }
    }
    
    public func registerWithEmail(email: String, code: String) async throws -> AuthResponse {
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
    
    public func loginWithEmailCode(email: String, code: String) async throws -> AuthResponse {
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
    
    public func loginWithPassword(email: String, password: String) async throws -> AuthResponse {
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
    
    public func setPassword(password: String, token: String, userId: String) async throws {
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
    
    public func changePassword(oldPassword: String, newPassword: String, token: String, userId: String) async throws {
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
    
    public func requestPasswordReset(email: String) async throws {
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
    
    public func resetPassword(email: String, code: String, newPassword: String) async throws -> AuthResponse {
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
    
    public func updateProfileName(profileName: String, token: String, userId: String) async throws -> User {
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
    public func resetCallTracking() {
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
    public func resetBehaviors() {
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
    public func configureAllToFail(with error: Error) {
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
    public func configureAllToEmptyState() {
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
