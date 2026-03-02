//
//  AppNotification.swift
//  AnonymousWallIos
//
//  Model representing a notification in the user's inbox
//

import Foundation

struct AppNotification: Codable, Identifiable, Equatable {
    let id: UUID
    /// Notification type: "COMMENT", "INTERNSHIP_COMMENT", or "MARKETPLACE_COMMENT"
    let type: String
    /// ID of the related entity (postId, internshipId, or marketplaceItemId)
    let entityId: UUID
    /// Snapshot of the entity title at notification creation time
    let entityTitle: String?
    /// Snapshot of the commenter's profile name at notification creation time
    let actorProfileName: String?
    /// Whether the notification has been read
    let read: Bool
    /// ISO-8601 creation timestamp
    let createdAt: String

    /// Returns a copy of this notification with `read` set to `true`.
    func markingAsRead() -> AppNotification {
        AppNotification(
            id: id,
            type: type,
            entityId: entityId,
            entityTitle: entityTitle,
            actorProfileName: actorProfileName,
            read: true,
            createdAt: createdAt
        )
    }

    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id
    }
}

struct NotificationListResponse: Codable {
    let data: [AppNotification]
    let pagination: PostListResponse.Pagination
}

struct UnreadCountResponse: Codable {
    let count: Int
}
