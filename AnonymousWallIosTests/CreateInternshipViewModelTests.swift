//
//  CreateInternshipViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for CreateInternshipViewModel - validation and creation logic
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct CreateInternshipViewModelTests {

    // MARK: - Initialization Tests

    @Test func testViewModelInitialization() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)

        #expect(viewModel.company.isEmpty)
        #expect(viewModel.role.isEmpty)
        #expect(viewModel.selectedWall == .campus)
        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Validation Tests

    @Test func testSubmitDisabledWhenCompanyEmpty() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)

        viewModel.company = ""
        viewModel.role = "Software Engineer Intern"

        #expect(viewModel.isSubmitDisabled == true)
    }

    @Test func testSubmitDisabledWhenRoleEmpty() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)

        viewModel.company = "Google"
        viewModel.role = ""

        #expect(viewModel.isSubmitDisabled == true)
    }

    @Test func testSubmitEnabledWithRequiredFields() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)

        viewModel.company = "Google"
        viewModel.role = "Software Engineer Intern"

        #expect(viewModel.isSubmitDisabled == false)
    }

    @Test func testSubmitDisabledWhenCompanyTooLong() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)

        viewModel.company = String(repeating: "a", count: 256)
        viewModel.role = "Role"

        #expect(viewModel.isSubmitDisabled == true)
        #expect(viewModel.isCompanyOverLimit == true)
    }

    @Test func testSubmitDisabledWhenRoleTooLong() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)

        viewModel.company = "Google"
        viewModel.role = String(repeating: "a", count: 256)

        #expect(viewModel.isSubmitDisabled == true)
        #expect(viewModel.isRoleOverLimit == true)
    }

    @Test func testCompanyAtLimit() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)

        viewModel.company = String(repeating: "a", count: 255)
        #expect(viewModel.isCompanyOverLimit == false)

        viewModel.company = String(repeating: "a", count: 256)
        #expect(viewModel.isCompanyOverLimit == true)
    }

    // MARK: - Create Tests

    @Test func testCreateWithEmptyCompany() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)
        let authState = createMockAuthState()

        viewModel.company = ""
        viewModel.role = "Role"

        var successCalled = false
        viewModel.createInternship(authState: authState) { successCalled = true }

        #expect(viewModel.errorMessage == "Company cannot be empty")
        #expect(successCalled == false)
    }

    @Test func testCreateWithEmptyRole() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)
        let authState = createMockAuthState()

        viewModel.company = "Google"
        viewModel.role = ""

        var successCalled = false
        viewModel.createInternship(authState: authState) { successCalled = true }

        #expect(viewModel.errorMessage == "Role cannot be empty")
        #expect(successCalled == false)
    }

    @Test func testCreateWithoutAuthentication() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)
        let authState = AuthState(loadPersistedState: false)

        viewModel.company = "Google"
        viewModel.role = "Intern"

        var successCalled = false
        viewModel.createInternship(authState: authState) { successCalled = true }

        #expect(viewModel.errorMessage == "Not authenticated")
        #expect(successCalled == false)
    }

    @Test func testCreateSuccess() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)
        let authState = createMockAuthState()

        viewModel.company = "Google"
        viewModel.role = "Software Engineer Intern"
        viewModel.salary = "$8000/month"
        viewModel.selectedWall = .national

        var successCalled = false
        viewModel.createInternship(authState: authState) { successCalled = true }

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
        #expect(mockService.createInternshipCalled == true)
    }

    @Test func testDefaultWallSelection() async throws {
        let mockService = MockInternshipService()
        let viewModel = CreateInternshipViewModel(service: mockService)
        #expect(viewModel.selectedWall == .campus)
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
            createdAt: "2026-02-19T00:00:00Z"
        )
        authState.currentUser = mockUser
        authState.authToken = "test-token"
        return authState
    }
}
