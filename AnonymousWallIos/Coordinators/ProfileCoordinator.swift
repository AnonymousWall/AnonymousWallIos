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
        case internshipDetail(Internship)  // ✅ Added
        case marketplaceDetail(MarketplaceItem)  // ✅ Added
        case setPassword
        case changePassword
        case editProfileName
    }
    
    @Published var path = NavigationPath()
    @Published var showSetPassword = false
    @Published var showChangePassword = false
    @Published var showEditProfileName = false
    @Published var selectedPost: Post?
    @Published var selectedInternship: Internship?  // ✅ Added
    @Published var selectedMarketplaceItem: MarketplaceItem?  // ✅ Added
    
    private var resetNavigationObserver: NSObjectProtocol?
    
    init() {
        resetNavigationObserver = NotificationCenter.default.addObserver(
            forName: .resetNavigation,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.path = NavigationPath()
                self?.selectedPost = nil
                self?.selectedInternship = nil
                self?.selectedMarketplaceItem = nil
            }
        }
    }
    
    deinit {
        if let observer = resetNavigationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func navigate(to destination: Destination) {
        switch destination {
        case .postDetail(let post):
            selectedPost = post
            path.append(destination)
        case .internshipDetail(let internship):  // ✅ Added
            selectedInternship = internship
            path.append(destination)
        case .marketplaceDetail(let item):  // ✅ Added
            selectedMarketplaceItem = item
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
