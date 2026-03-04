//
//  NotificationModels.swift
//  AnonymousWallIos
//

import Foundation

struct AppNotification: Codable, Identifiable {
    let id: String
    let type: NotificationType
    let entityId: String
    let entityTitle: String?        // currently always null from backend — handle gracefully
    let actorProfileName: String?   // currently always null from backend — handle gracefully
    let read: Bool
    let createdAt: String

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
    let page: Int           // 1-based current page
    let size: Int
    let totalElements: Int
    let totalPages: Int

    var hasMore: Bool {
        page < totalPages
    }
}
