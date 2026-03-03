//
//  NotificationModels.swift
//  AnonymousWallIos
//

import Foundation

struct AppNotification: Codable, Identifiable {
    let id: String
    let type: NotificationType
    let entityId: String
    let wall: String?
    let entityTitle: String?
    let actorProfileName: String?
    let read: Bool
    let createdAt: String

    /// Returns a copy of this notification with the `read` flag set to `newRead`.
    func copying(read newRead: Bool) -> AppNotification {
        AppNotification(
            id: id,
            type: type,
            entityId: entityId,
            wall: wall,
            entityTitle: entityTitle,
            actorProfileName: actorProfileName,
            read: newRead,
            createdAt: createdAt
        )
    }

    enum NotificationType: String, Codable {
        case comment = "COMMENT"
        case internshipComment = "INTERNSHIP_COMMENT"
        case marketplaceComment = "MARKETPLACE_COMMENT"
        case unknown

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            self = NotificationType(rawValue: raw) ?? .unknown
        }
    }
}

struct UnreadCountResponse: Codable {
    let count: Int
}

struct NotificationListResponse: Codable {
    let content: [AppNotification]
    let totalSize: Int
    let pageNumber: Int
    let size: Int
}
