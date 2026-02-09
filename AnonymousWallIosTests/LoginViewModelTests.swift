//
//  LoginViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for LoginViewModel - authentication flows, validation, error handling
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct LoginViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)
        
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.verificationCode.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isSendingCode == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.successMessage == nil)
        #expect(viewModel.loginMethod == .password)
        #expect(viewModel.resendCountdown == 0)
    }
    
    // MARK: - Login Button State Tests
    
    @Test func testLoginButtonDisabledWhenPasswordMethodAndEmailEmpty() async throws {
        let viewModel = LoginViewModel(authService: MockAuthService())
        viewModel.loginMethod = .password
        viewModel.email = ""
        viewModel.password = "password123"
        
        #expect(viewModel.isLoginButtonDisabled == true)
    }
    
    @Test func testLoginButtonDisabledWhenPasswordMethodAndPasswordEmpty() async throws {
        let viewModel = LoginViewModel(authService: MockAuthService())
        viewModel.loginMethod = .password
        viewModel.email = "test@example.com"
        viewModel.password = ""
        
        #expect(viewModel.isLoginButtonDisabled == true)
    }
    
    @Test func testLoginButtonEnabledWhenPasswordMethodAndBothFilled() async throws {
        let viewModel = LoginViewModel(authService: MockAuthService())
        viewModel.loginMethod = .password
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        #expect(viewModel.isLoginButtonDisabled == false)
    }
    
    @Test func testLoginButtonDisabledWhenCodeMethodAndEmailEmpty() async throws {
        let viewModel = LoginViewModel(authService: MockAuthService())
        viewModel.loginMethod = .verificationCode
        viewModel.email = ""
        viewModel.verificationCode = "123456"
        
        #expect(viewModel.isLoginButtonDisabled == true)
    }
    
    @Test func testLoginButtonDisabledWhenCodeMethodAndCodeEmpty() async throws {
        let viewModel = LoginViewModel(authService: MockAuthService())
        viewModel.loginMethod = .verificationCode
        viewModel.email = "test@example.com"
        viewModel.verificationCode = ""
        
        #expect(viewModel.isLoginButtonDisabled == true)
    }
    
    @Test func testLoginButtonEnabledWhenCodeMethodAndBothFilled() async throws {
        let viewModel = LoginViewModel(authService: MockAuthService())
        viewModel.loginMethod = .verificationCode
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        
        #expect(viewModel.isLoginButtonDisabled == false)
    }
    
    // MARK: - Request Verification Code Tests
    
    @Test func testRequestVerificationCodeWithEmptyEmail() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)
        viewModel.email = ""
        
        viewModel.requestVerificationCode()
        
        // Should not call service when email is empty
        #expect(mockAuthService.sendEmailVerificationCodeCalled == false)
    }
    
    @Test func testRequestVerificationCodeWithInvalidEmail() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)
        viewModel.email = "invalid-email"
        
        viewModel.requestVerificationCode()
        
        // Should set error message for invalid email
        #expect(viewModel.errorMessage == "Please enter a valid email address")
        #expect(mockAuthService.sendEmailVerificationCodeCalled == false)
    }
    
    @Test func testRequestVerificationCodeSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)
        viewModel.email = "test@example.com"
        
        viewModel.requestVerificationCode()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 500_000_000) // 0.1 seconds
        
        #expect(mockAuthService.sendEmailVerificationCodeCalled == true)
        #expect(viewModel.successMessage == "Verification code sent to your email!")
        #expect(viewModel.isSendingCode == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testRequestVerificationCodeFailure() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.sendEmailVerificationCodeBehavior = .failure(MockAuthService.MockError.networkError)
        let viewModel = LoginViewModel(authService: mockAuthService)
        viewModel.email = "test@example.com"
        
        viewModel.requestVerificationCode()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(mockAuthService.sendEmailVerificationCodeCalled == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSendingCode == false)
        #expect(viewModel.successMessage == nil)
    }
    
    // MARK: - Login with Password Tests
    
    @Test func testLoginWithPasswordSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .password
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        viewModel.login(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(mockAuthService.loginWithPasswordCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(authState.isAuthenticated == true)
        #expect(authState.authToken == "mock-token")
    }
    
    @Test func testLoginWithPasswordFailure() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.loginWithPasswordBehavior = .failure(MockAuthService.MockError.invalidCredentials)
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .password
        viewModel.email = "test@example.com"
        viewModel.password = "wrongpassword"
        
        viewModel.login(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(mockAuthService.loginWithPasswordCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(authState.isAuthenticated == false)
    }
    
    @Test func testLoginWithPasswordEmptyEmail() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .password
        viewModel.email = ""
        viewModel.password = "password123"
        
        viewModel.login(authState: authState)
        
        // Should not call service when email is empty
        #expect(mockAuthService.loginWithPasswordCalled == false)
    }
    
    // MARK: - Login with Email Code Tests
    
    @Test func testLoginWithEmailCodeSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .verificationCode
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        
        viewModel.login(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(mockAuthService.loginWithEmailCodeCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(authState.isAuthenticated == true)
        #expect(authState.authToken == "mock-token")
    }
    
    @Test func testLoginWithEmailCodeFailure() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.loginWithEmailCodeBehavior = .failure(MockAuthService.MockError.invalidCode)
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .verificationCode
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "999999"
        
        viewModel.login(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(mockAuthService.loginWithEmailCodeCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(authState.isAuthenticated == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testNetworkErrorHandling() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.loginWithPasswordBehavior = .failure(MockAuthService.MockError.networkError)
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .password
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        viewModel.login(authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testUnauthorizedErrorHandling() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.loginWithPasswordBehavior = .failure(MockAuthService.MockError.unauthorized)
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .password
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        viewModel.login(authState: authState)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
        #expect(authState.isAuthenticated == false)
    }
    
    // MARK: - State Management Tests
    
    @Test func testLoadingStatesDuringLogin() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .password
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        #expect(viewModel.isLoading == false)
        
        viewModel.login(authState: authState)
        
        // Note: In production, isLoading would be true briefly, but async operations
        // complete too fast in tests to reliably observe intermediate states
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testErrorMessageClearedOnNewLogin() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.loginWithPasswordBehavior = .failure(MockAuthService.MockError.invalidCredentials)
        let viewModel = LoginViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.loginMethod = .password
        viewModel.email = "test@example.com"
        viewModel.password = "wrong"
        
        // First login attempt fails
        viewModel.login(authState: authState)
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(viewModel.errorMessage != nil)
        
        // Configure mock to succeed
        mockAuthService.loginWithPasswordBehavior = .success
        
        // Second login attempt should clear error
        viewModel.login(authState: authState)
        
        // Note: errorMessage is cleared immediately when login is called
        // We can't reliably test the intermediate state in this simple test
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Helper Methods
    
    private func createMockAuthState() -> AuthState {
        return AuthState(loadPersistedState: false)
    }
}
