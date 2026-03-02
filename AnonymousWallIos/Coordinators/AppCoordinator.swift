//
//  AppCoordinator.swift
//  AnonymousWallIos
//
//  Main application coordinator
//

import SwiftUI

/// Main app coordinator managing high-level navigation
@MainActor
class AppCoordinator: ObservableObject {
    @Published var authCoordinator = AuthCoordinator()
    @Published var tabCoordinator = TabCoordinator()
    
    let authState: AuthState
    
    init(authState: AuthState) {
        self.authState = authState
    }
    
    /// Navigates to the correct screen based on the push notification destination.
    ///
    /// Comment/internship/marketplace notifications open the Notifications tab so the user
    /// sees the full inbox first (TikTok-style), then taps the row to reach the content.
    /// Chat notifications still deep-link directly to the Messages tab.
    func navigate(to destination: PushNotificationDestination) {
        switch destination {
        case .post, .internship, .marketplace:
            // Switch to Notifications tab — the inbox shows all received notifications.
            // Tapping a row in NotificationInboxView navigates to the specific content.
            tabCoordinator.selectTab(6)

        case .chat:
            tabCoordinator.selectTab(5) // Messages tab — keep direct deep-link for chat
        }
    }

    /// Navigates to a post by ID — convenience wrapper for backwards compatibility.
    func navigateToPost(id: UUID) {
        navigate(to: .post(id, wall: "national"))
    }
}
