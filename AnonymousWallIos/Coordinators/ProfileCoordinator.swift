//
//  ProfileCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for profile navigation
//

import SwiftUI

/// Coordinator for managing profile navigation
@MainActor
class ProfileCoordinator: Coordinator {
    enum Destination: Hashable {
        case postDetail(Post)
        case internshipDetail(Internship)
        case marketplaceDetail(MarketplaceItem)
        case setPassword
        case changePassword
        case editProfileName
    }
    
    @Published var path = NavigationPath()
    @Published var showSetPassword = false
    @Published var showChangePassword = false
    @Published var showEditProfileName = false
    @Published var selectedPost: Post?
    
    func navigate(to destination: Destination) {
        switch destination {
        case .postDetail(let post):
            selectedPost = post
            path.append(destination)
        case .internshipDetail:
            path.append(destination)
        case .marketplaceDetail:
            path.append(destination)
        case .setPassword:
            showSetPassword = true
        case .changePassword:
            showChangePassword = true
        case .editProfileName:
            showEditProfileName = true
        }
    }
    
    func dismissSetPassword() {
        showSetPassword = false
    }
    
    func dismissChangePassword() {
        showChangePassword = false
    }
    
    func dismissEditProfileName() {
        showEditProfileName = false
    }
}
