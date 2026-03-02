//
//  NotificationInboxServiceProtocol.swift
//  AnonymousWallIos
//
//  Protocol for notification inbox API operations
//

import Foundation

protocol NotificationInboxServiceProtocol {
    /// Fetch a paginated list of notifications for the authenticated user.
    func getNotifications(
        token: String,
        userId: String,
        page: Int,
        size: Int
    ) async throws -> NotificationListResponse

    /// Return the number of unread notifications for the authenticated user.
    func getUnreadCount(token: String, userId: String) async throws -> Int

    /// Mark all notifications as read for the authenticated user.
    func markAllRead(token: String, userId: String) async throws

    /// Mark a single notification as read.
    func markRead(notificationId: UUID, token: String, userId: String) async throws
}
