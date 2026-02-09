//
//  ChangePasswordViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for ChangePasswordViewModel - password change flows, validation
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct ChangePasswordViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        
        #expect(viewModel.oldPassword.isEmpty)
        #expect(viewModel.newPassword.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showSuccess == false)
    }
    
    // MARK: - Button State Tests
    
    @Test func testButtonDisabledWhenOldPasswordEmpty() async throws {
        let viewModel = ChangePasswordViewModel(authService: MockAuthService())
        
        viewModel.oldPassword = ""
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        #expect(viewModel.isButtonDisabled == true)
    }
    
    @Test func testButtonDisabledWhenNewPasswordEmpty() async throws {
        let viewModel = ChangePasswordViewModel(authService: MockAuthService())
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = ""
        viewModel.confirmPassword = "newpassword123"
        
        #expect(viewModel.isButtonDisabled == true)
    }
    
    @Test func testButtonDisabledWhenConfirmPasswordEmpty() async throws {
        let viewModel = ChangePasswordViewModel(authService: MockAuthService())
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = ""
        
        #expect(viewModel.isButtonDisabled == true)
    }
    
    @Test func testButtonEnabledWhenAllFieldsFilled() async throws {
        let viewModel = ChangePasswordViewModel(authService: MockAuthService())
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        #expect(viewModel.isButtonDisabled == false)
    }
    
    // MARK: - Change Password Tests
    
    @Test func testChangePasswordWithEmptyFields() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.oldPassword = ""
        viewModel.newPassword = ""
        viewModel.confirmPassword = ""
        
        var successCalled = false
        viewModel.changePassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Please fill in all fields")
        #expect(mockAuthService.changePasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testChangePasswordWithMismatchedPasswords() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "differentpassword"
        
        var successCalled = false
        viewModel.changePassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "New passwords do not match")
        #expect(mockAuthService.changePasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testChangePasswordWithShortPassword() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "short"
        viewModel.confirmPassword = "short"
        
        var successCalled = false
        viewModel.changePassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Password must be at least 8 characters")
        #expect(mockAuthService.changePasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testChangePasswordWithoutAuthentication() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = AuthState(loadPersistedState: false) // Not authenticated
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        var successCalled = false
        viewModel.changePassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Not authenticated")
        #expect(mockAuthService.changePasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testChangePasswordSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        var successCalled = false
        viewModel.changePassword(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 1_500_000_000) // Wait for success callback (includes 1s delay in ViewModel)
        
        #expect(mockAuthService.changePasswordCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
    }
    
    @Test func testChangePasswordFailureWithWrongOldPassword() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.changePasswordBehavior = .failure(MockAuthService.MockError.invalidCredentials)
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.oldPassword = "wrongoldpassword"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        var successCalled = false
        viewModel.changePassword(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(mockAuthService.changePasswordCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showSuccess == false)
        #expect(viewModel.errorMessage != nil)
        #expect(successCalled == false)
    }
    
    @Test func testChangePasswordNetworkError() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.changePasswordBehavior = .failure(MockAuthService.MockError.networkError)
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        var successCalled = false
        viewModel.changePassword(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(mockAuthService.changePasswordCalled == true)
        #expect(viewModel.errorMessage != nil)
        #expect(successCalled == false)
    }
    
    // MARK: - Validation Tests
    
    @Test func testNewPasswordMinimumLength() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        // Test passwords with different lengths
        let testCases = [
            ("1234567", true),  // 7 characters - should fail
            ("12345678", false), // 8 characters - should pass
            ("123456789", false) // 9 characters - should pass
        ]
        
        for (password, shouldFail) in testCases {
            mockAuthService.resetCallTracking()
            viewModel.errorMessage = nil
            viewModel.oldPassword = "oldpassword123"
            viewModel.newPassword = password
            viewModel.confirmPassword = password
            
            viewModel.changePassword(authState: authState) {}
            
            if shouldFail {
                #expect(viewModel.errorMessage == "Password must be at least 8 characters")
            } else {
                #expect(viewModel.errorMessage != "Password must be at least 8 characters")
            }
        }
    }
    
    @Test func testNewPasswordMatching() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        // Test matching passwords
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        viewModel.changePassword(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.errorMessage != "New passwords do not match")
        
        // Test non-matching passwords
        mockAuthService.resetCallTracking()
        viewModel.errorMessage = nil
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "differentpassword"
        viewModel.changePassword(authState: authState) {}
        
        #expect(viewModel.errorMessage == "New passwords do not match")
    }
    
    // MARK: - State Management Tests
    
    @Test func testShowSuccessStateAfterChangePassword() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.oldPassword = "oldpassword123"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        #expect(viewModel.showSuccess == false)
        
        viewModel.changePassword(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        #expect(viewModel.showSuccess == true)
    }
    
    @Test func testErrorMessageClearedOnNewAttempt() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.changePasswordBehavior = .failure(MockAuthService.MockError.invalidCredentials)
        let viewModel = ChangePasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.oldPassword = "wrongpassword"
        viewModel.newPassword = "newpassword123"
        viewModel.confirmPassword = "newpassword123"
        
        // First attempt fails
        viewModel.changePassword(authState: authState) {}
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(viewModel.errorMessage != nil)
        
        // Configure to succeed
        mockAuthService.changePasswordBehavior = .success
        
        // Second attempt should clear error
        viewModel.changePassword(authState: authState) {}
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Helper Methods
    
    private func createMockAuthState() -> AuthState {
        let authState = AuthState(loadPersistedState: false)
        let mockUser = User(
            id: "test-user-id",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-02-09T00:00:00Z"
        )
        authState.currentUser = mockUser
        authState.authToken = "test-token"
        return authState
    }
}
