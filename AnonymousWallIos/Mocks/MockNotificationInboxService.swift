//
//  MockNotificationInboxService.swift
//  AnonymousWallIos
//
//  Mock implementation of NotificationInboxServiceProtocol for unit testing
//

import Foundation

class MockNotificationInboxService: NotificationInboxServiceProtocol {

    // MARK: - Configuration

    enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }

    enum MockError: Error, LocalizedError {
        case notFound
        case unauthorized
        case networkError

        var errorDescription: String? {
            switch self {
            case .notFound: return "Notification not found"
            case .unauthorized: return "Unauthorized access"
            case .networkError: return "Network error"
            }
        }
    }

    // MARK: - State Tracking

    var getNotificationsCalled = false
    var getUnreadCountCalled = false
    var markAllReadCalled = false
    var markReadCalled = false
    var lastMarkedReadId: UUID?

    // MARK: - Configurable Behavior

    var getNotificationsBehavior: MockBehavior = .success
    var getUnreadCountBehavior: MockBehavior = .success
    var markAllReadBehavior: MockBehavior = .success
    var markReadBehavior: MockBehavior = .success

    // MARK: - Configurable State

    var mockNotifications: [AppNotification] = []
    var mockUnreadCount: Int = 0

    // MARK: - Initialization

    init() {}

    // MARK: - Protocol Implementation

    func getNotifications(
        token: String,
        userId: String,
        page: Int,
        size: Int
    ) async throws -> NotificationListResponse {
        getNotificationsCalled = true

        switch getNotificationsBehavior {
        case .success:
            return NotificationListResponse(
                data: mockNotifications,
                pagination: PostListResponse.Pagination(
                    page: page,
                    limit: size,
                    total: mockNotifications.count,
                    totalPages: mockNotifications.isEmpty ? 0 : (mockNotifications.count + size - 1) / size
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return NotificationListResponse(
                data: [],
                pagination: PostListResponse.Pagination(page: page, limit: size, total: 0, totalPages: 0)
            )
        }
    }

    func getUnreadCount(token: String, userId: String) async throws -> Int {
        getUnreadCountCalled = true

        switch getUnreadCountBehavior {
        case .success:
            return mockUnreadCount
        case .failure(let error):
            throw error
        case .emptyState:
            return 0
        }
    }

    func markAllRead(token: String, userId: String) async throws {
        markAllReadCalled = true

        switch markAllReadBehavior {
        case .success:
            mockUnreadCount = 0
        case .failure(let error):
            throw error
        case .emptyState:
            break
        }
    }

    func markRead(notificationId: UUID, token: String, userId: String) async throws {
        markReadCalled = true
        lastMarkedReadId = notificationId

        switch markReadBehavior {
        case .success:
            if mockUnreadCount > 0 {
                mockUnreadCount -= 1
            }
        case .failure(let error):
            throw error
        case .emptyState:
            break
        }
    }

    // MARK: - Helper Methods

    func resetCallTracking() {
        getNotificationsCalled = false
        getUnreadCountCalled = false
        markAllReadCalled = false
        markReadCalled = false
        lastMarkedReadId = nil
    }

    func resetBehaviors() {
        getNotificationsBehavior = .success
        getUnreadCountBehavior = .success
        markAllReadBehavior = .success
        markReadBehavior = .success
    }

    func clearMockData() {
        mockNotifications.removeAll()
        mockUnreadCount = 0
    }
}
