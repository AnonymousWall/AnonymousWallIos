//
//  ForgotPasswordViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for ForgotPasswordViewModel - password reset flows, validation
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct ForgotPasswordViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        
        #expect(viewModel.email.isEmpty)
        #expect(viewModel.verificationCode.isEmpty)
        #expect(viewModel.newPassword.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isSendingCode == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.codeSent == false)
        #expect(viewModel.showSuccess == false)
        #expect(viewModel.resendCountdown == 0)
    }
    
    // MARK: - Request Reset Tests
    
    @Test func testRequestResetWithEmptyEmail() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        
        viewModel.email = ""
        viewModel.requestReset()
        
        #expect(viewModel.errorMessage == "Please enter your email")
        #expect(mockAuthService.sendEmailVerificationCodeCalled == false)
    }
    
    @Test func testRequestResetWithInvalidEmail() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        
        viewModel.email = "invalid-email"
        viewModel.requestReset()
        
        #expect(viewModel.errorMessage == "Please enter a valid email address")
        #expect(mockAuthService.sendEmailVerificationCodeCalled == false)
    }
    
    @Test func testRequestResetSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        
        viewModel.email = "test@example.com"
        viewModel.requestReset()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockAuthService.sendEmailVerificationCodeCalled == true)
        #expect(viewModel.codeSent == true)
        #expect(viewModel.isSendingCode == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testRequestResetFailure() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.sendEmailVerificationCodeBehavior = .failure(MockAuthService.MockError.networkError)
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        
        viewModel.email = "test@example.com"
        viewModel.requestReset()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockAuthService.sendEmailVerificationCodeCalled == true)
        #expect(viewModel.codeSent == false)
        #expect(viewModel.isSendingCode == false)
        #expect(viewModel.errorMessage != nil)
    }
    
    // MARK: - Reset Password Tests
    
    @Test func testResetPasswordWithEmptyFields() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = ""
        viewModel.verificationCode = ""
        viewModel.newPassword = ""
        viewModel.confirmPassword = ""
        
        var successCalled = false
        viewModel.resetPassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Please fill in all fields")
        #expect(mockAuthService.resetPasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testResetPasswordWithMismatchedPasswords() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        viewModel.newPassword = "password123"
        viewModel.confirmPassword = "password456"
        
        var successCalled = false
        viewModel.resetPassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Passwords do not match")
        #expect(mockAuthService.resetPasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testResetPasswordWithShortPassword() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        viewModel.newPassword = "short"
        viewModel.confirmPassword = "short"
        
        var successCalled = false
        viewModel.resetPassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Password must be at least 8 characters")
        #expect(mockAuthService.resetPasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testResetPasswordSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        var successCalled = false
        viewModel.resetPassword(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 1_200_000_000) // Wait for success callback
        
        #expect(mockAuthService.resetPasswordCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.errorMessage == nil)
        #expect(authState.isAuthenticated == true)
        #expect(successCalled == true)
    }
    
    @Test func testResetPasswordFailure() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.resetPasswordBehavior = .failure(MockAuthService.MockError.invalidCode)
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "999999"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        var successCalled = false
        viewModel.resetPassword(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockAuthService.resetPasswordCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showSuccess == false)
        #expect(viewModel.errorMessage != nil)
        #expect(authState.isAuthenticated == false)
        #expect(successCalled == false)
    }
    
    // MARK: - Validation Tests
    
    @Test func testPasswordValidation() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        // Test minimum length requirement
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        viewModel.newPassword = "1234567" // 7 characters
        viewModel.confirmPassword = "1234567"
        
        viewModel.resetPassword(authState: authState) {}
        
        #expect(viewModel.errorMessage == "Password must be at least 8 characters")
        
        // Test with 8 characters (should pass validation)
        viewModel.errorMessage = nil
        viewModel.newPassword = "12345678" // 8 characters
        viewModel.confirmPassword = "12345678"
        
        viewModel.resetPassword(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Should not fail on length validation anymore
        #expect(viewModel.errorMessage != "Password must be at least 8 characters")
    }
    
    @Test func testEmailValidation() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        
        let invalidEmails = ["invalid", "@example.com", "user@"]
        
        for email in invalidEmails {
            viewModel.email = email
            viewModel.errorMessage = nil
            viewModel.requestReset()
            
            #expect(viewModel.errorMessage == "Please enter a valid email address")
            #expect(mockAuthService.sendEmailVerificationCodeCalled == false)
            mockAuthService.resetCallTracking()
        }
    }
    
    // MARK: - Auto-Login Tests
    
    @Test func testAutoLoginAfterSuccessfulReset() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        #expect(authState.isAuthenticated == false)
        
        viewModel.resetPassword(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        #expect(authState.isAuthenticated == true)
        #expect(authState.authToken == "mock-token")
    }
    
    // MARK: - State Management Tests
    
    @Test func testCodeSentStateAfterRequestReset() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        
        viewModel.email = "test@example.com"
        #expect(viewModel.codeSent == false)
        
        viewModel.requestReset()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.codeSent == true)
    }
    
    @Test func testShowSuccessStateAfterReset() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ForgotPasswordViewModel(authService: mockAuthService)
        let authState = AuthState()
        
        viewModel.email = "test@example.com"
        viewModel.verificationCode = "123456"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        #expect(viewModel.showSuccess == false)
        
        viewModel.resetPassword(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        #expect(viewModel.showSuccess == true)
    }
}
