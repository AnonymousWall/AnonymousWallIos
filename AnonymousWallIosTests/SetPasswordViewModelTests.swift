//
//  SetPasswordViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for SetPasswordViewModel - initial password setup, validation
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct SetPasswordViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showSuccess == false)
    }
    
    // MARK: - Button State Tests
    
    @Test func testButtonDisabledWhenPasswordEmpty() async throws {
        let viewModel = SetPasswordViewModel(authService: MockAuthService())
        
        viewModel.password = ""
        viewModel.confirmPassword = "password123"
        
        #expect(viewModel.isButtonDisabled == true)
    }
    
    @Test func testButtonDisabledWhenConfirmPasswordEmpty() async throws {
        let viewModel = SetPasswordViewModel(authService: MockAuthService())
        
        viewModel.password = "password123"
        viewModel.confirmPassword = ""
        
        #expect(viewModel.isButtonDisabled == true)
    }
    
    @Test func testButtonEnabledWhenBothFieldsFilled() async throws {
        let viewModel = SetPasswordViewModel(authService: MockAuthService())
        
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        
        #expect(viewModel.isButtonDisabled == false)
    }
    
    // MARK: - Set Password Tests
    
    @Test func testSetPasswordWithEmptyFields() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.password = ""
        viewModel.confirmPassword = ""
        
        var successCalled = false
        viewModel.setPassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Please fill in all fields")
        #expect(mockAuthService.setPasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testSetPasswordWithMismatchedPasswords() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.password = "password123"
        viewModel.confirmPassword = "password456"
        
        var successCalled = false
        viewModel.setPassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Passwords do not match")
        #expect(mockAuthService.setPasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testSetPasswordWithShortPassword() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.password = "short"
        viewModel.confirmPassword = "short"
        
        var successCalled = false
        viewModel.setPassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Password must be at least 8 characters")
        #expect(mockAuthService.setPasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testSetPasswordWithoutAuthentication() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = AuthState(loadPersistedState: false) // Not authenticated
        
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        
        var successCalled = false
        viewModel.setPassword(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Not authenticated")
        #expect(mockAuthService.setPasswordCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testSetPasswordSuccess() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        
        var successCalled = false
        viewModel.setPassword(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 1_200_000_000) // Wait for success callback
        
        #expect(mockAuthService.setPasswordCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
    }
    
    @Test func testSetPasswordFailure() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.setPasswordBehavior = .failure(MockAuthService.MockError.networkError)
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        
        var successCalled = false
        viewModel.setPassword(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(mockAuthService.setPasswordCalled == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.showSuccess == false)
        #expect(viewModel.errorMessage != nil)
        #expect(successCalled == false)
    }
    
    // MARK: - Validation Tests
    
    @Test func testPasswordMinimumLength() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
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
            viewModel.password = password
            viewModel.confirmPassword = password
            
            viewModel.setPassword(authState: authState) {}
            
            if shouldFail {
                #expect(viewModel.errorMessage == "Password must be at least 8 characters")
            } else {
                #expect(viewModel.errorMessage != "Password must be at least 8 characters")
            }
        }
    }
    
    @Test func testPasswordMatching() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        // Test matching passwords
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        viewModel.setPassword(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(viewModel.errorMessage != "Passwords do not match")
        
        // Test non-matching passwords
        mockAuthService.resetCallTracking()
        viewModel.errorMessage = nil
        viewModel.password = "password123"
        viewModel.confirmPassword = "differentpassword"
        viewModel.setPassword(authState: authState) {}
        
        #expect(viewModel.errorMessage == "Passwords do not match")
    }
    
    // MARK: - State Management Tests
    
    @Test func testShowSuccessStateAfterSetPassword() async throws {
        let mockAuthService = MockAuthService()
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        
        #expect(viewModel.showSuccess == false)
        
        viewModel.setPassword(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        #expect(viewModel.showSuccess == true)
    }
    
    @Test func testErrorMessageClearedOnNewAttempt() async throws {
        let mockAuthService = MockAuthService()
        mockAuthService.setPasswordBehavior = .failure(MockAuthService.MockError.networkError)
        let viewModel = SetPasswordViewModel(authService: mockAuthService)
        let authState = createMockAuthState()
        
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        
        // First attempt fails
        viewModel.setPassword(authState: authState) {}
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(viewModel.errorMessage != nil)
        
        // Configure to succeed
        mockAuthService.setPasswordBehavior = .success
        
        // Second attempt should clear error
        viewModel.setPassword(authState: authState) {}
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
            passwordSet: false,
            createdAt: "2026-02-09T00:00:00Z"
        )
        authState.currentUser = mockUser
        authState.authToken = "test-token"
        return authState
    }
}
