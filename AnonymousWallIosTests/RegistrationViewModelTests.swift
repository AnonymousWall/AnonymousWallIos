//
//  RegistrationViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for RegistrationViewModel - registration flows, validation, error handling
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct RegistrationViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.verificationCode.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isSendingCode == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.codeSent == false)
        #expect(viewModel.showingSuccess == false)
        #expect(viewModel.resendCountdown == 0)
    }
    
    // MARK: - Send Verification Code Tests
    
    @Test func testSendVerificationCodeWithEmptyEmail() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        viewModel.email = ""
        
        viewModel.sendVerificationCode()
        
        #expect(viewModel.errorMessage == "Please enter your email")
        #expect(mockAuthService.sendEmailVerificationCodeCalled == false)
    }
    
    @Test func testSendVerificationCodeWithInvalidEmail() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        viewModel.email = "invalid-email"
        
        viewModel.sendVerificationCode()
        
        #expect(viewModel.errorMessage == "Please enter a valid email address")
        #expect(mockAuthService.sendEmailVerificationCodeCalled == false)
    }
    
    @Test func testSendVerificationCodeSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        viewModel.email = "test@example.com"
        
        viewModel.sendVerificationCode()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(mockAuthService.sendEmailVerificationCodeCalled == true)
        #expect(viewModel.codeSent == true)
        #expect(viewModel.isSendingCode == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testSendVerificationCodeFailure() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.sendEmailVerificationCodeBehavior = .failure(MockAuthService.MockError.networkError)
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        viewModel.email = "test@example.com"
        
        viewModel.sendVerificationCode()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockAuthService.sendEmailVerificationCodeCalled == true)
        #expect(viewModel.codeSent == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSendingCode == false)
    }
    
    // MARK: - Register Tests
    
    @Test func testRegisterWithEmptyEmail() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = ""
        viewModel.verificationCode = "123456"
        
        viewModel.register(authState: authState)
        
        #expect(viewModel.errorMessage == "Please enter both email and verification code")
        #expect(mockAuthService.registerWithEmailCalled == false)
    }
    
    @Test func testRegisterWithEmptyCode() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = ""
        
        viewModel.register(authState: authState)
        
        #expect(viewModel.errorMessage == "Please enter both email and verification code")
        #expect(mockAuthService.registerWithEmailCalled == false)
    }
    
    @Test func testRegisterSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        
        viewModel.register(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockAuthService.registerWithEmailCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showingSuccess == true)
        #expect(viewModel.errorMessage == nil)
        #expect(authState.isAuthenticated == true)
        #expect(authState.authToken == "mock-token")
    }
    
    @Test func testRegisterFailure() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.registerWithEmailBehavior = .failure(MockAuthService.MockError.invalidCode)
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "999999"
        
        viewModel.register(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockAuthService.registerWithEmailCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showingSuccess == false)
        #expect(viewModel.errorMessage != nil)
        #expect(authState.isAuthenticated == false)
    }
    
    @Test func testRegisterWithExistingUser() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.registerWithEmailBehavior = .failure(MockAuthService.MockError.userAlreadyExists)
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "existing@example.com"
        viewModel.verificationCode = "123456"
        
        viewModel.register(authState: authState)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockAuthService.registerWithEmailCalled == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.showingSuccess == false)
        #expect(authState.isAuthenticated == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testNetworkErrorHandling() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.registerWithEmailBehavior = .failure(MockAuthService.MockError.networkError)
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        
        viewModel.register(authState: authState)
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
        #expect(authState.isAuthenticated == false)
    }
    
    @Test func testErrorMessageClearedOnNewRegistration() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.registerWithEmailBehavior = .failure(MockAuthService.MockError.invalidCode)
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "999999"
        
        // First attempt fails
        viewModel.register(authState: authState)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(viewModel.errorMessage != nil)
        
        // Configure mock to succeed
        mockAuthService.registerWithEmailBehavior = .success
        mockAuthService.resetCallTracking()
        
        // Second attempt should clear error
        viewModel.register(authState: authState)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingSuccess == true)
    }
    
    // MARK: - State Management Tests
    
    @Test func testCodeSentStateAfterSendingCode() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        
        viewModel.email = "test@example.com"
        #expect(viewModel.codeSent == false)
        
        viewModel.sendVerificationCode()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.codeSent == true)
    }
    
    @Test func testShowingSuccessStateAfterRegistration() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        #expect(viewModel.showingSuccess == false)
        
        viewModel.register(authState: authState)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.showingSuccess == true)
    }
    
    @Test func testAutoLoginAfterSuccessfulRegistration() async throws {
        let mockAuthService = MockAuthService()
        let customUser = User(
            id: "new-user-id",
            email: "newuser@example.com",
            profileName: "Anonymous",
            isVerified: true,
            passwordSet: false,
            createdAt: "2026-02-09T00:00:00Z"
        )
        mockAuthService.mockUser = customUser
        
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "newuser@example.com"
        viewModel.verificationCode = "123456"
        
        #expect(authState.isAuthenticated == false)
        
        viewModel.register(authState: authState)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(authState.isAuthenticated == true)
        #expect(authState.currentUser?.email == "newuser@example.com")
        #expect(authState.authToken == "mock-token")
    }
    
    // MARK: - Validation Tests
    
    @Test func testEmailValidationWithValidEmails() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+tag@example.org"
        ]
        
        for email in validEmails {
            viewModel.email = email
            mockAuthService.resetCallTracking()
            
            viewModel.sendVerificationCode()
            try await Task.sleep(nanoseconds: 50_000_000)
            
            #expect(mockAuthService.sendEmailVerificationCodeCalled == true)
            #expect(viewModel.errorMessage == nil)
        }
    }
    
    @Test func testEmailValidationWithInvalidEmails() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = RegistrationViewModel(authService: mockAuthService)
        
        let invalidEmails = [
            "invalid",
            "@example.com",
            "user@",
            ""
        ]
        
        for email in invalidEmails {
            viewModel.email = email
            mockAuthService.resetCallTracking()
            viewModel.errorMessage = nil
            
            viewModel.sendVerificationCode()
            
            if email.isEmpty {
                #expect(viewModel.errorMessage == "Please enter your email")
            } else {
                #expect(viewModel.errorMessage == "Please enter a valid email address")
            }
            #expect(mockAuthService.sendEmailVerificationCodeCalled == false)
        }
    }
}
