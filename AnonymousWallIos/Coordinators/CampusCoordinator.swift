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
    
    weak var tabCoordinator: TabCoordinator?
    
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
        case .setPassword:
            showSetPassword = true
        }
    }
    
    func dismissSetPassword() {
        showSetPassword = false
    }
    
    func navigateToChatWithUser(userId: String, userName: String) {
        // ✅ FIX: Switch tab first, then navigate to chat AFTER a brief delay.
        //
        // Without the delay, both happen in the same runloop tick:
        // 1. selectTab(3) → MessagesView appears → ConversationsListView.onAppear → loadConversations starts
        // 2. navigate(to: .chatDetail) → ConversationsListView.onDisappear fires IMMEDIATELY
        // 3. disconnect() or task cancellation kills the in-flight loadConversations request
        // 4. Error popup: "Failed to load conversations: request cancelled"
        //
        // With the delay, we let ConversationsListView fully appear and finish
        // loading before pushing ChatView on top of it.
        
        tabCoordinator?.selectTab(5) // Switch to Messages tab
        
        Task { @MainActor in
            // Wait one runloop tick for the tab switch + ConversationsListView
            // onAppear to complete before pushing ChatView
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.1 seconds
            tabCoordinator?.chatCoordinator.navigate(
                to: .chatDetail(otherUserId: userId, otherUserName: userName)
            )
        }
    }
}
