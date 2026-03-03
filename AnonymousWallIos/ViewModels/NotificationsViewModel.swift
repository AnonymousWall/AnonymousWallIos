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

    func loadNotifications(authState: AuthState) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 0
        hasMore = true

        do {
            let response = try await service.getNotifications(page: 0, authState: authState)
            notifications = response.content
            hasMore = !response.last
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
            hasMore = !response.last
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
            notifications = notifications.map { notification in
                AppNotification(
                    id: notification.id,
                    type: notification.type,
                    entityId: notification.entityId,
                    wall: notification.wall,
                    entityTitle: notification.entityTitle,
                    actorProfileName: notification.actorProfileName,
                    read: true,
                    createdAt: notification.createdAt
                )
            }
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
                let n = notifications[index]
                notifications[index] = AppNotification(
                    id: n.id,
                    type: n.type,
                    entityId: n.entityId,
                    wall: n.wall,
                    entityTitle: n.entityTitle,
                    actorProfileName: n.actorProfileName,
                    read: true,
                    createdAt: n.createdAt
                )
            }
            unreadCount = max(0, unreadCount - 1)
        } catch {
            // Silently fail — not critical
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
