//
//  NotificationsService.swift
//  AnonymousWallIos
//

import Foundation

class NotificationsService {
    static let shared = NotificationsService()
    private let networkClient = NetworkClient.shared
    private init() {}

    /// Page is 1-based. First call passes page=1.
    func getNotifications(page: Int, size: Int = 20, authState: AuthState) async throws -> NotificationListResponse {
        guard let token = await authState.authToken,
              let userId = await authState.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }
        let request = try APIRequestBuilder()
            .setPath("/notifications?page=\(page)&size=\(size)")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()
        return try await networkClient.performRequest(request)
    }

    func getUnreadCount(authState: AuthState) async throws -> Int {
        guard let token = await authState.authToken,
              let userId = await authState.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }
        let request = try APIRequestBuilder()
            .setPath("/notifications/unread-count")
            .setMethod(.GET)
            .setToken(token)
            .setUserId(userId)
            .build()
        let response: UnreadCountResponse = try await networkClient.performRequest(request)
        return response.count
    }

    func markAllRead(authState: AuthState) async throws {
        guard let token = await authState.authToken,
              let userId = await authState.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }
        let request = try APIRequestBuilder()
            .setPath("/notifications/mark-all-read")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .build()
        try await networkClient.performRequestWithoutResponse(request)
    }

    func markRead(notificationId: String, authState: AuthState) async throws {
        guard let token = await authState.authToken,
              let userId = await authState.currentUser?.id else {
            throw URLError(.userAuthenticationRequired)
        }
        let request = try APIRequestBuilder()
            .setPath("/notifications/\(notificationId)/read")
            .setMethod(.POST)
            .setToken(token)
            .setUserId(userId)
            .build()
        try await networkClient.performRequestWithoutResponse(request)
    }
}
