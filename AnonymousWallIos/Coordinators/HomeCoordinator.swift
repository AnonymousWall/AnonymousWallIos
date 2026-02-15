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
}
