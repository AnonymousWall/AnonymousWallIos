//
//  BlockViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for BlockViewModel using MockBlockService
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct BlockViewModelTests {

    // MARK: - Load Block List Tests

    @Test func testLoadBlockList_success() async throws {
        let (viewModel, mockService) = createTestViewModel()
        let authState = createMockAuthState()

        mockService.mockBlockedUsers = [
            BlockedUser(blockedUserId: "user-a", createdAt: "2026-01-01T00:00:00Z"),
            BlockedUser(blockedUserId: "user-b", createdAt: "2026-01-02T00:00:00Z")
        ]

        viewModel.loadBlockList(authState: authState)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.getBlockListCalled == true)
        #expect(viewModel.blockedUsers.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func testLoadBlockList_empty() async throws {
        let (viewModel, mockService) = createTestViewModel()
        let authState = createMockAuthState()

        mockService.getBlockListBehavior = .emptyState

        viewModel.loadBlockList(authState: authState)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.getBlockListCalled == true)
        #expect(viewModel.blockedUsers.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func testLoadBlockList_failure() async throws {
        let (viewModel, mockService) = createTestViewModel()
        let authState = createMockAuthState()

        mockService.getBlockListBehavior = .failure(MockBlockService.MockError.networkError)

        viewModel.loadBlockList(authState: authState)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.getBlockListCalled == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.blockedUsers.isEmpty)
    }

    // MARK: - Block User Tests

    @Test func testBlockUser_success() async throws {
        let (viewModel, mockService) = createTestViewModel()
        let authState = createMockAuthState()

        var onSuccessCalled = false

        viewModel.blockUser(targetUserId: "target-user", authState: authState) {
            onSuccessCalled = true
        }
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.blockUserCalled == true)
        #expect(onSuccessCalled == true)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func testBlockUser_failure() async throws {
        let (viewModel, mockService) = createTestViewModel()
        let authState = createMockAuthState()

        mockService.blockUserBehavior = .failure(MockBlockService.MockError.networkError)

        var onSuccessCalled = false

        viewModel.blockUser(targetUserId: "target-user", authState: authState) {
            onSuccessCalled = true
        }
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.blockUserCalled == true)
        #expect(onSuccessCalled == false)
        #expect(viewModel.errorMessage != nil)
    }

    // MARK: - Unblock User Tests

    @Test func testUnblockUser_success() async throws {
        let (viewModel, mockService) = createTestViewModel()
        let authState = createMockAuthState()

        viewModel.blockedUsers = [
            BlockedUser(blockedUserId: "user-a", createdAt: "2026-01-01T00:00:00Z"),
            BlockedUser(blockedUserId: "user-b", createdAt: "2026-01-02T00:00:00Z")
        ]

        var onSuccessCalled = false

        viewModel.unblockUser(targetUserId: "user-a", authState: authState) {
            onSuccessCalled = true
        }
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.unblockUserCalled == true)
        #expect(onSuccessCalled == true)
        #expect(viewModel.blockedUsers.count == 1)
        #expect(viewModel.blockedUsers.first?.blockedUserId == "user-b")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func testUnblockUser_failure() async throws {
        let (viewModel, mockService) = createTestViewModel()
        let authState = createMockAuthState()

        viewModel.blockedUsers = [
            BlockedUser(blockedUserId: "user-a", createdAt: "2026-01-01T00:00:00Z")
        ]

        mockService.unblockUserBehavior = .failure(MockBlockService.MockError.networkError)

        var onSuccessCalled = false

        viewModel.unblockUser(targetUserId: "user-a", authState: authState) {
            onSuccessCalled = true
        }
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(mockService.unblockUserCalled == true)
        #expect(onSuccessCalled == false)
        #expect(viewModel.errorMessage != nil)
        // The user should still be in the list on failure
        #expect(viewModel.blockedUsers.count == 1)
    }

    // MARK: - Test Helpers

    private func createTestViewModel() -> (BlockViewModel, MockBlockService) {
        let mockService = MockBlockService()
        let viewModel = BlockViewModel(blockService: mockService)
        return (viewModel, mockService)
    }

    private func createMockAuthState() -> AuthState {
        let authState = AuthState()
        let mockUser = User(
            id: "user1",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01T00:00:00Z"
        )
        authState.currentUser = mockUser
        authState.authToken = "test-token"
        return authState
    }
}
