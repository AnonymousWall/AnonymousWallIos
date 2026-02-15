//
//  CampusCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for campus feed navigation
//

import SwiftUI

/// Coordinator for managing campus feed navigation
@MainActor
class CampusCoordinator: Coordinator {
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
