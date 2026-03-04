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

    private var currentPage = 1   // 1-based — next page to fetch
    private var hasMore = true
    private let service = NotificationsService.shared
    
    @Published var pendingNavigation: AppNotification? = nil

    func loadNotifications(authState: AuthState) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 1
        hasMore = true

        do {
            let response = try await service.getNotifications(page: 1, authState: authState)
            notifications = response.content
            hasMore = response.hasMore
            currentPage = 2   // next fetch will be page 2
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
            hasMore = response.hasMore
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
            // Optimistically update all local notifications to read
            notifications = notifications.map { marking($0, read: true) }
            unreadCount = 0
        } catch {
            errorMessage = "Failed to mark all as read"
        }
    }

    func markRead(_ notification: AppNotification, authState: AuthState) async {
        guard !notification.read else { return }
        do {
            try await service.markRead(notificationId: notification.id, authState: authState)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = marking(notifications[index], read: true)
            }
            unreadCount = max(0, unreadCount - 1)
        } catch {
            // Silently fail — not critical
        }
    }

    // MARK: - Helpers

    private func marking(_ notification: AppNotification, read: Bool) -> AppNotification {
        AppNotification(
            id: notification.id,
            type: notification.type,
            entityId: notification.entityId,
            entityTitle: notification.entityTitle,
            actorProfileName: notification.actorProfileName,
            read: read,
            createdAt: notification.createdAt
        )
    }

    func fetchUnreadCount(authState: AuthState) async {
        do {
            unreadCount = try await service.getUnreadCount(authState: authState)
        } catch {
            // Silently fail — badge just won't update
        }
    }
}
