//
//  CreateMarketplaceViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for CreateMarketplaceViewModel - validation and creation logic
//

import Testing
import UIKit
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

    @Test func testSubmitDisabledWhenLoadingImages() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        viewModel.title = "Used Textbook"
        viewModel.priceText = "25.00"
        viewModel.isLoadingImages = true

        #expect(viewModel.isSubmitDisabled == true)
    }

    @Test func testIsLoadingImagesInitiallyFalse() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        #expect(viewModel.isLoadingImages == false)
    }

    @Test func testImageLoadProgressInitiallyZero() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        #expect(viewModel.imageLoadProgress == 0)
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

    // MARK: - Image Management Tests

    @Test func testInitialImageState() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)

        #expect(viewModel.selectedImages.isEmpty)
        #expect(viewModel.imageCount == 0)
        #expect(viewModel.canAddMoreImages == true)
        #expect(viewModel.remainingImageSlots == 5)
    }

    @Test func testAddImage() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }

        viewModel.addImage(image)

        #expect(viewModel.imageCount == 1)
        #expect(viewModel.remainingImageSlots == 4)
        #expect(viewModel.canAddMoreImages == true)
    }

    @Test func testAddImagesUpToMax() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }

        for _ in 0..<5 {
            viewModel.addImage(image)
        }

        #expect(viewModel.imageCount == 5)
        #expect(viewModel.canAddMoreImages == false)
        #expect(viewModel.remainingImageSlots == 0)
    }

    @Test func testAddImageBeyondMaxSetsError() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }

        for _ in 0..<5 {
            viewModel.addImage(image)
        }
        viewModel.addImage(image)

        #expect(viewModel.imageCount == 5)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func testRemoveImage() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }

        viewModel.addImage(image)
        viewModel.addImage(image)
        viewModel.removeImage(at: 0)

        #expect(viewModel.imageCount == 1)
    }

    @Test func testRemoveImageOutOfBoundsIsIgnored() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }

        viewModel.addImage(image)
        viewModel.removeImage(at: 5)

        #expect(viewModel.imageCount == 1)
    }

    @Test func testCreateItemPassesImagesToService() async throws {
        let mockService = MockMarketplaceService()
        let viewModel = CreateMarketplaceViewModel(service: mockService)
        let authState = createMockAuthState()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }

        viewModel.title = "Textbook"
        viewModel.priceText = "10.00"
        viewModel.addImage(image)

        viewModel.createItem(authState: authState) {}

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(mockService.createItemCalled == true)
        #expect(mockService.capturedImages.count == 1)
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
