//
//  NotificationsViewModel.swift
//  AnonymousWallIos
//

import SwiftUI

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private var hasMore = true
    private let service = NotificationsService.shared

    var badgeText: String {
        unreadCount > 9 ? "9+" : "\(unreadCount)"
    }

    func loadNotifications(authState: AuthState) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 0
        hasMore = true

        do {
            let response = try await service.getNotifications(page: 0, authState: authState)
            notifications = response.content
            hasMore = notifications.count < response.totalSize
            currentPage = 1
        } catch {
            errorMessage = "Failed to load notifications"
        }

        isLoading = false
    }

    func loadMore(authState: AuthState) async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true

        do {
            let response = try await service.getNotifications(page: currentPage, authState: authState)
            notifications.append(contentsOf: response.content)
            hasMore = notifications.count < response.totalSize
            currentPage += 1
        } catch {
            // Silently fail for pagination
        }

        isLoadingMore = false
    }

    func refresh(authState: AuthState) async {
        await loadNotifications(authState: authState)
        await fetchUnreadCount(authState: authState)
    }

    func markAllRead(authState: AuthState) async {
        do {
            try await service.markAllRead(authState: authState)
            notifications = notifications.map { $0.copying(read: true) }
            unreadCount = 0
        } catch {
            errorMessage = "Failed to mark all as read"
        }
    }

    func markRead(_ notification: AppNotification, authState: AuthState) async {
        guard !notification.read else { return }
        // Optimistically update the badge and row immediately so the UI responds
        // without waiting for the network round-trip.
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notifications[index].copying(read: true)
        }
        unreadCount = max(0, unreadCount - 1)
        do {
            try await service.markRead(notificationId: notification.id, authState: authState)
        } catch {
            // Revert optimistic update on failure
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = notifications[index].copying(read: false)
            }
            unreadCount += 1
        }
    }

    func fetchUnreadCount(authState: AuthState) async {
        do {
            unreadCount = try await service.getUnreadCount(authState: authState)
        } catch {
            // Silently fail — badge just won't update
        }
    }
}
