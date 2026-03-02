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
    func navigate(to destination: PushNotificationDestination) {
        switch destination {
        case .post(let postId, let wall):
                if wall == "campus" {
                    tabCoordinator.selectTab(1) // Campus tab — verify index against TabCoordinator
                    tabCoordinator.campusCoordinator.navigate(to: .postDetailById(postId.uuidString))
                } else {
                    tabCoordinator.selectTab(0) // National/Home tab
                    tabCoordinator.homeCoordinator.navigate(to: .postDetailById(postId.uuidString))
                }

        case .internship(let internshipId):
            tabCoordinator.selectTab(3)
            tabCoordinator.internshipCoordinator.navigate(to: .internshipDetailById(internshipId.uuidString))

        case .marketplace(let itemId):
            tabCoordinator.selectTab(4)
            tabCoordinator.marketplaceCoordinator.navigate(to: .itemDetailById(itemId.uuidString))
        }
    }

    /// Navigates to a post by ID — convenience wrapper for backwards compatibility.
    func navigateToPost(id: UUID) {
        navigate(to: .post(id, wall: "national"))
    }
}
