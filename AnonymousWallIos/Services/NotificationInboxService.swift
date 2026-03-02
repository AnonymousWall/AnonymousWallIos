//
//  NotificationInboxService.swift
//  AnonymousWallIos
//
//  Real implementation of NotificationInboxServiceProtocol
//

import Foundation

class NotificationInboxService: NotificationInboxServiceProtocol {
    static let shared: NotificationInboxServiceProtocol = NotificationInboxService()

    private let networkClient = NetworkClient.shared

    private init() {}

    func getNotifications(
        token: String,
        userId: String,
        page: Int,
        size: Int
    ) async throws -> NotificationListResponse {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]

        let request = try APIRequestBuilder()
            .setPath("/notifications")
            .setMethod(.GET)
            .addQueryItems(queryItems)
            .setToken(token)
            .setUserId(userId)
            .build()

        return try await networkClient.performRequest(request)
    }

    func getUnreadCount(token: String, userId: String) async throws -> Int {
        let request = try APIRequestBuilder()
            .setPath("/notifications/unread-count")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()

        let response: UnreadCountResponse = try await networkClient.performRequest(request)
        return response.count
    }

    func markAllRead(token: String, userId: String) async throws {
        let request = try APIRequestBuilder()
            .setPath("/notifications/mark-all-read")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .build()

        try await networkClient.performRequestWithoutResponse(request)
    }

    func markRead(notificationId: UUID, token: String, userId: String) async throws {
        let request = try APIRequestBuilder()
            .setPath("/notifications/\(notificationId.uuidString)/read")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .build()

        try await networkClient.performRequestWithoutResponse(request)
    }
}
