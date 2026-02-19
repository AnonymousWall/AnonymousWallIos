//
//  CreateMarketplaceViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for CreateMarketplaceViewModel - validation and creation logic
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct CreateMarketplaceViewModelTests {

    // MARK: - Initialization Tests

    @Test func testViewModelInitialization() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        #expect(viewModel.title.isEmpty)
        #expect(viewModel.priceText.isEmpty)
        #expect(viewModel.selectedWall == .campus)
        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Price Validation Tests

    @Test func testValidPrice() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.priceText = "45.99"
        #expect(viewModel.isPriceValid == true)
        #expect(viewModel.parsedPrice == 45.99)
    }

    @Test func testZeroPrice() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.priceText = "0"
        #expect(viewModel.isPriceValid == true)
    }

    @Test func testNegativePrice() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.priceText = "-5"
        #expect(viewModel.isPriceValid == false)
    }

    @Test func testInvalidPriceText() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.priceText = "abc"
        #expect(viewModel.isPriceValid == false)
        #expect(viewModel.parsedPrice == nil)
    }

    // MARK: - Submit Disabled Tests

    @Test func testSubmitDisabledWhenTitleEmpty() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.title = ""
        viewModel.priceText = "10.00"

        #expect(viewModel.isSubmitDisabled == true)
    }

    @Test func testSubmitDisabledWhenPriceEmpty() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.title = "Textbook"
        viewModel.priceText = ""

        #expect(viewModel.isSubmitDisabled == true)
    }

    @Test func testSubmitDisabledWhenPriceInvalid() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.title = "Textbook"
        viewModel.priceText = "abc"

        #expect(viewModel.isSubmitDisabled == true)
    }

    @Test func testSubmitEnabledWithValidData() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.title = "Used Textbook"
        viewModel.priceText = "25.00"

        #expect(viewModel.isSubmitDisabled == false)
    }

    @Test func testTitleOverLimit() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.title = String(repeating: "a", count: 256)
        viewModel.priceText = "10.00"

        #expect(viewModel.isTitleOverLimit == true)
        #expect(viewModel.isSubmitDisabled == true)
    }

    // MARK: - Create Tests

    @Test func testCreateWithEmptyTitle() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let authState = createMockAuthState()

        viewModel.title = ""
        viewModel.priceText = "10.00"

        var successCalled = false
        viewModel.createItem(authState: authState) { successCalled = true }

        #expect(viewModel.errorMessage == "Title cannot be empty")
        #expect(successCalled == false)
    }

    @Test func testCreateWithInvalidPrice() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let authState = createMockAuthState()

        viewModel.title = "Textbook"
        viewModel.priceText = "-5"

        var successCalled = false
        viewModel.createItem(authState: authState) { successCalled = true }

        #expect(viewModel.errorMessage != nil)
        #expect(successCalled == false)
    }

    @Test func testCreateWithoutAuthentication() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let authState = AuthState(loadPersistedState: false)

        viewModel.title = "Textbook"
        viewModel.priceText = "10.00"

        var successCalled = false
        viewModel.createItem(authState: authState) { successCalled = true }

        #expect(viewModel.errorMessage == "Not authenticated")
        #expect(successCalled == false)
    }

    @Test func testCreateSuccess() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let authState = createMockAuthState()

        viewModel.title = "Used Calculus Textbook"
        viewModel.priceText = "45.99"
        viewModel.selectedCondition = "like_new"
        viewModel.selectedWall = .national

        var successCalled = false
        viewModel.createItem(authState: authState) { successCalled = true }

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(viewModel.isPosting == false)
        #expect(viewModel.errorMessage == nil)
        #expect(successCalled == true)
        #expect(mockService.createItemCalled == true)
    }

    @Test func testDefaultWallSelection() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
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
