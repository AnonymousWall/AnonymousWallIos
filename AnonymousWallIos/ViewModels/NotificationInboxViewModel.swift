//
//  NotificationInboxViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for the notification inbox screen
//

import SwiftUI

@MainActor
class NotificationInboxViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var pagination = Pagination()
    private var loadTask: Task<Void, Never>?
    private let service: NotificationInboxServiceProtocol

    // MARK: - Initialization

    init(service: NotificationInboxServiceProtocol = NotificationInboxService.shared) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadNotifications(authState: AuthState) {
        loadTask?.cancel()
        loadTask = Task {
            await performLoad(authState: authState)
        }
    }

    func refresh(authState: AuthState) async {
        loadTask?.cancel()
        pagination.reset()
        loadTask = Task {
            await performLoad(authState: authState)
        }
        await loadTask?.value
    }

    func loadMoreIfNeeded(for notification: AppNotification, authState: AuthState) {
        guard !isLoadingMore && pagination.hasMorePages else { return }
        guard notification.id == notifications.last?.id else { return }

        Task {
            guard !isLoadingMore && pagination.hasMorePages else { return }
            isLoadingMore = true
            await performLoadMore(authState: authState)
        }
    }

    func loadUnreadCount(authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }

        Task {
            do {
                unreadCount = try await service.getUnreadCount(token: token, userId: userId)
            } catch {
                // Silently ignore unread count errors — badge is non-critical
            }
        }
    }

    func markAllRead(authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }

        Task {
            do {
                try await service.markAllRead(token: token, userId: userId)
                unreadCount = 0
                notifications = notifications.map { notification in
                    notification.read ? notification : notification.markingAsRead()
                }
            } catch {
                // Non-critical: silently ignore
            }
        }
    }

    func markRead(_ notification: AppNotification, authState: AuthState) {
        guard !notification.read,
              let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }

        Task {
            do {
                try await service.markRead(notificationId: notification.id, token: token, userId: userId)
                if let index = notifications.firstIndex(of: notification) {
                    notifications[index] = notification.markingAsRead()
                }
                if unreadCount > 0 {
                    unreadCount -= 1
                }
            } catch {
                // Non-critical: silently ignore
            }
        }
    }

    func cleanup() {
        loadTask?.cancel()
    }

    // MARK: - Private Methods

    private func performLoad(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await service.getNotifications(
                token: token,
                userId: userId,
                page: pagination.currentPage,
                size: 20
            )
            notifications = response.data
            pagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performLoadMore(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMore = false
            return
        }

        defer { isLoadingMore = false }

        let nextPage = pagination.advanceToNextPage()

        do {
            let response = try await service.getNotifications(
                token: token,
                userId: userId,
                page: nextPage,
                size: 20
            )
            notifications.append(contentsOf: response.data)
            pagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
