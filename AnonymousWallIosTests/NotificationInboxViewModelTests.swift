//
//  NotificationInboxViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for NotificationInboxViewModel
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct NotificationInboxViewModelTests {

    // MARK: - Helpers

    private func makeAuthState() -> AuthState {
        let state = AuthState()
        state.currentUser = User(
            id: "user-1",
            email: "test@example.com",
            profileName: "Test User",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01T00:00:00Z"
        )
        state.authToken = "test-token"
        return state
    }

    private func makeNotification(
        id: UUID = UUID(),
        type: String = "COMMENT",
        read: Bool = false
    ) -> AppNotification {
        AppNotification(
            id: id,
            type: type,
            entityId: UUID(),
            entityTitle: "Test Post Title",
            actorProfileName: "Jane Commenter",
            read: read,
            createdAt: "2026-03-01T12:00:00Z"
        )
    }

    // MARK: - Initialisation

    @Test func testInitialState() {
        let viewModel = NotificationInboxViewModel(service: MockNotificationInboxService())

        #expect(viewModel.notifications.isEmpty)
        #expect(viewModel.unreadCount == 0)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Load Notifications

    @Test func testLoadNotificationsSuccess() async throws {
        let service = MockNotificationInboxService()
        service.mockNotifications = [
            makeNotification(type: "COMMENT"),
            makeNotification(type: "INTERNSHIP_COMMENT")
        ]
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadNotifications(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(service.getNotificationsCalled == true)
        #expect(viewModel.notifications.count == 2)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func testLoadNotificationsEmpty() async throws {
        let service = MockNotificationInboxService()
        service.getNotificationsBehavior = .emptyState
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadNotifications(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(service.getNotificationsCalled == true)
        #expect(viewModel.notifications.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func testLoadNotificationsFailure() async throws {
        let service = MockNotificationInboxService()
        service.getNotificationsBehavior = .failure(MockNotificationInboxService.MockError.networkError)
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadNotifications(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(service.getNotificationsCalled == true)
        #expect(viewModel.notifications.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func testLoadNotificationsRequiresAuthToken() async throws {
        let service = MockNotificationInboxService()
        let viewModel = NotificationInboxViewModel(service: service)
        let unauthenticated = AuthState() // no token

        viewModel.loadNotifications(authState: unauthenticated)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(service.getNotificationsCalled == false)
        #expect(viewModel.notifications.isEmpty)
    }

    // MARK: - Unread Count

    @Test func testLoadUnreadCount() async throws {
        let service = MockNotificationInboxService()
        service.mockUnreadCount = 5
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadUnreadCount(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(service.getUnreadCountCalled == true)
        #expect(viewModel.unreadCount == 5)
    }

    @Test func testLoadUnreadCountIgnoresErrors() async throws {
        let service = MockNotificationInboxService()
        service.getUnreadCountBehavior = .failure(MockNotificationInboxService.MockError.networkError)
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadUnreadCount(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        // Error is silently swallowed — unreadCount stays 0, no errorMessage
        #expect(viewModel.unreadCount == 0)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Mark All Read

    @Test func testMarkAllReadCallsService() async throws {
        let service = MockNotificationInboxService()
        service.mockUnreadCount = 3
        let n1 = makeNotification(read: false)
        let n2 = makeNotification(read: false)
        service.mockNotifications = [n1, n2]
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadNotifications(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        viewModel.markAllRead(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(service.markAllReadCalled == true)
        #expect(viewModel.unreadCount == 0)
        #expect(viewModel.notifications.allSatisfy { $0.read })
    }

    @Test func testMarkAllReadIgnoresErrors() async throws {
        let service = MockNotificationInboxService()
        service.mockUnreadCount = 2
        service.markAllReadBehavior = .failure(MockNotificationInboxService.MockError.networkError)
        let viewModel = NotificationInboxViewModel(service: service)
        viewModel.unreadCount = 2

        viewModel.markAllRead(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        // Error is silently swallowed — errorMessage stays nil
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Mark Read

    @Test func testMarkReadCallsServiceForUnreadNotification() async throws {
        let service = MockNotificationInboxService()
        service.mockUnreadCount = 1
        let notification = makeNotification(read: false)
        service.mockNotifications = [notification]
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadNotifications(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        let unread = viewModel.notifications.first!
        viewModel.markRead(unread, authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(service.markReadCalled == true)
        #expect(service.lastMarkedReadId == unread.id)
        #expect(viewModel.notifications.first?.read == true)
    }

    @Test func testMarkReadSkipsAlreadyReadNotification() async throws {
        let service = MockNotificationInboxService()
        let alreadyRead = makeNotification(read: true)
        service.mockNotifications = [alreadyRead]
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadNotifications(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        viewModel.markRead(alreadyRead, authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        // Should NOT call the service for an already-read notification
        #expect(service.markReadCalled == false)
    }

    @Test func testMarkReadDecrementsUnreadCount() async throws {
        let service = MockNotificationInboxService()
        service.mockUnreadCount = 3
        let notification = makeNotification(read: false)
        service.mockNotifications = [notification]
        let viewModel = NotificationInboxViewModel(service: service)

        viewModel.loadNotifications(authState: makeAuthState())
        viewModel.loadUnreadCount(authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        let unread = viewModel.notifications.first!
        viewModel.markRead(unread, authState: makeAuthState())
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(viewModel.unreadCount == 2)
    }

    // MARK: - Refresh

    @Test func testRefreshReloadsFromFirstPage() async throws {
        let service = MockNotificationInboxService()
        service.mockNotifications = [makeNotification()]
        let viewModel = NotificationInboxViewModel(service: service)

        await viewModel.refresh(authState: makeAuthState())

        #expect(service.getNotificationsCalled == true)
        #expect(viewModel.notifications.count == 1)
    }
}
