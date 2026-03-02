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
    
    /// Navigates to a post by ID, switching to the Home tab immediately.
    /// PostDetailView fetches the full post data when it appears — no pre-fetch needed.
    func navigateToPost(id: UUID) {
        tabCoordinator.selectTab(0)
        tabCoordinator.homeCoordinator.navigate(to: .postDetailById(id.uuidString))
    }
}
