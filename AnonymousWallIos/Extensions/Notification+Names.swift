//
//  Notification+Names.swift
//  AnonymousWallIos
//

import Foundation

extension Notification.Name {
    /// Posted by NetworkClient after a successful silent token refresh.
    /// userInfo key: "token" → String (the new access token)
    /// Observed by ChatRepository to keep cachedToken and WebSocket token current.
    static let tokenRefreshed = Notification.Name("com.anonymouswall.tokenRefreshed")
}
