//
//  HomeCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for home (national) feed navigation
//

import SwiftUI

/// Coordinator for managing home feed navigation
@MainActor
class HomeCoordinator: Coordinator {
    enum Destination: Hashable {
        case postDetail(Post)
        case setPassword
    }
    
    @Published var path = NavigationPath()
    @Published var showSetPassword = false
    @Published var selectedPost: Post?
    
    weak var tabCoordinator: TabCoordinator?
    
    func navigate(to destination: Destination) {
        switch destination {
        case .postDetail(let post):
            selectedPost = post
            path.append(destination)
        case .setPassword:
            showSetPassword = true
        }
    }
    
    func dismissSetPassword() {
        showSetPassword = false
    }
    
    func navigateToChatWithUser(userId: String, userName: String) {
        // Switch to Messages tab and navigate to chat
        tabCoordinator?.selectTab(3) // Messages tab index
        tabCoordinator?.chatCoordinator.navigate(to: .chatDetail(otherUserId: userId, otherUserName: userName))
    }
}
