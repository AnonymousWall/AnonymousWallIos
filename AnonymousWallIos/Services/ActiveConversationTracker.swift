//
//  ActiveConversationTracker.swift
//  AnonymousWallIos
//
//  Tracks which conversation the user is currently viewing.
//  Used to suppress push notification banners when already in the conversation.
//

import Foundation

/// Tracks which conversation the user is currently viewing.
/// Accessed only from the main thread (UNUserNotificationCenterDelegate and SwiftUI lifecycle).
class ActiveConversationTracker {
    static let shared = ActiveConversationTracker()
    private init() {}
    var activeConversationId: String?
}
