//
//  EditProfileNameViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for EditProfileNameViewModel - profile name updates
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct EditProfileNameViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitialization() async throws {
        let mockUserService = MockUserService()
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        
        #expect(viewModel.profileName.isEmpty)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testViewModelCanBeInitializedWithMockService() async throws {
        let mockUserService = MockUserService()
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        
        #expect(viewModel.profileName.isEmpty)
    }
    
    @Test func testViewModelCanBeInitializedWithDefaultService() async throws {
        let viewModel = EditProfileNameViewModel()
        
        #expect(viewModel.profileName.isEmpty)
    }
    
    // MARK: - Load Current Profile Name Tests
    
    @Test func testLoadCurrentProfileNameWithNonAnonymousUser() async throws {
        let viewModel = EditProfileNameViewModel()
        let user = User(
            id: "test-id",
            email: "test@example.com",
            profileName: "John Doe",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-02-09T00:00:00Z"
        )
        
        viewModel.loadCurrentProfileName(from: user)
        
        #expect(viewModel.profileName == "John Doe")
    }
    
    @Test func testLoadCurrentProfileNameWithAnonymousUser() async throws {
        let viewModel = EditProfileNameViewModel()
        let user = User(
            id: "test-id",
            email: "test@example.com",
            profileName: "Anonymous",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-02-09T00:00:00Z"
        )
        
        viewModel.loadCurrentProfileName(from: user)
        
        // Anonymous should be converted to empty string for editing
        #expect(viewModel.profileName.isEmpty)
    }
    
    @Test func testLoadCurrentProfileNameWithNilUser() async throws {
        let viewModel = EditProfileNameViewModel()
        
        viewModel.loadCurrentProfileName(from: nil)
        
        // Should remain empty
        #expect(viewModel.profileName.isEmpty)
    }
    
    // MARK: - Update Profile Name Tests
    
    @Test func testUpdateProfileNameWithoutAuthentication() async throws {
        let mockUserService = MockUserService()
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = AuthState() // Not authenticated
        
        viewModel.profileName = "New Name"
        
        var successCalled = false
        viewModel.updateProfileName(authState: authState) {
            successCalled = true
        }
        
        #expect(viewModel.errorMessage == "Authentication required")
        #expect(mockUserService.updateProfileNameCalled == false)
        #expect(successCalled == false)
    }
    
    @Test func testUpdateProfileNameSuccess() async throws {
        let mockUserService = MockUserService()
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        viewModel.profileName = "Jane Smith"
        
        var successCalled = false
        viewModel.updateProfileName(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockUserService.updateProfileNameCalled == true)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
    }
    
    @Test func testUpdateProfileNameFailure() async throws {
        let mockUserService = MockUserService()
        mockUserService.updateProfileNameBehavior = .failure(MockUserService.MockError.networkError)
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        viewModel.profileName = "New Name"
        
        var successCalled = false
        viewModel.updateProfileName(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockUserService.updateProfileNameCalled == true)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage != nil)
        #expect(successCalled == false)
    }
    
    @Test func testUpdateProfileNameWithEmptyString() async throws {
        let mockUserService = MockUserService()
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        // Empty string should be sent as-is (backend will set to Anonymous)
        viewModel.profileName = ""
        
        var successCalled = false
        viewModel.updateProfileName(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockUserService.updateProfileNameCalled == true)
        #expect(successCalled == true)
    }
    
    @Test func testUpdateProfileNameWithWhitespaceOnly() async throws {
        let mockUserService = MockUserService()
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        // Whitespace-only should be trimmed to empty string
        viewModel.profileName = "   \n  "
        
        var successCalled = false
        viewModel.updateProfileName(authState: authState) {
            successCalled = true
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockUserService.updateProfileNameCalled == true)
        #expect(successCalled == true)
    }
    
    // MARK: - Trimming Tests
    
    @Test func testProfileNameTrimming() async throws {
        let mockUserService = MockUserService()
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        viewModel.profileName = "  John Doe  "
        
        viewModel.updateProfileName(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Should succeed with trimmed name
        #expect(mockUserService.updateProfileNameCalled == true)
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - Auth State Update Tests
    
    @Test func testAuthStateUpdatedAfterSuccessfulUpdate() async throws {
        let mockUserService = MockUserService()
        let updatedUser = User(
            id: "test-user-id",
            email: "test@example.com",
            profileName: "Updated Name",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-02-09T00:00:00Z"
        )
        mockUserService.mockUser = updatedUser
        
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        #expect(authState.currentUser?.profileName == "Test User")
        
        viewModel.profileName = "Updated Name"
        viewModel.updateProfileName(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(authState.currentUser?.profileName == "Updated Name")
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testNetworkErrorHandling() async throws {
        let mockUserService = MockUserService()
        mockUserService.updateProfileNameBehavior = .failure(MockUserService.MockError.networkError)
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        viewModel.profileName = "New Name"
        viewModel.updateProfileName(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSubmitting == false)
    }
    
    @Test func testUnauthorizedErrorHandling() async throws {
        let mockUserService = MockUserService()
        mockUserService.updateProfileNameBehavior = .failure(MockUserService.MockError.unauthorized)
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        viewModel.profileName = "New Name"
        viewModel.updateProfileName(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSubmitting == false)
    }
    
    @Test func testErrorMessageClearedOnNewUpdate() async throws {
        let mockUserService = MockUserService()
        mockUserService.updateProfileNameBehavior = .failure(MockUserService.MockError.networkError)
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        // First attempt fails
        viewModel.profileName = "New Name"
        viewModel.updateProfileName(authState: authState) {}
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(viewModel.errorMessage != nil)
        
        // Configure to succeed
        mockUserService.updateProfileNameBehavior = .success
        
        // Second attempt should clear error
        viewModel.updateProfileName(authState: authState) {}
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - State Management Tests
    
    @Test func testIsSubmittingStateDuringUpdate() async throws {
        let mockUserService = MockUserService()
        let viewModel = EditProfileNameViewModel(userService: mockUserService)
        let authState = createMockAuthState()
        
        viewModel.profileName = "New Name"
        
        #expect(viewModel.isSubmitting == false)
        
        viewModel.updateProfileName(authState: authState) {}
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(viewModel.isSubmitting == false)
    }
    
    // MARK: - Helper Methods
    
    private func createMockAuthState() -> AuthState {
        let authState = AuthState()
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
