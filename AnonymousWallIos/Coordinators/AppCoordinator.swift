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
    
    /// Navigates to a post by ID, switching to the Home tab and fetching the post if needed.
    /// Used for deep linking from push notification taps.
    func navigateToPost(id: UUID, authState: AuthState) {
        tabCoordinator.selectTab(0)
        Task { @MainActor in
            guard let token = authState.authToken,
                  let userId = authState.currentUser?.id else { return }
            do {
                let post = try await PostService.shared.getPost(
                    postId: id.uuidString,
                    token: token,
                    userId: userId
                )
                tabCoordinator.homeCoordinator.navigate(to: .postDetail(post))
            } catch {
                // Non-fatal — deep link failure should not affect app functionality
                print("[DeepLink] Failed to navigate to post \(id): \(error.localizedDescription)")
            }
        }
    }
}
