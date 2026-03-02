//
//  NotificationCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for notification inbox navigation
//

import SwiftUI

/// Coordinator for managing navigation within the Notifications tab
@MainActor
class NotificationCoordinator: Coordinator {
    enum Destination: Hashable {
        /// Navigate to a post detail by its ID
        case postDetailById(String)
        /// Navigate to an internship detail by its ID
        case internshipDetailById(String)
        /// Navigate to a marketplace item detail by its ID
        case marketplaceDetailById(String)
    }

    @Published var path = NavigationPath()

    weak var tabCoordinator: TabCoordinator?

    private var resetNavigationObserver: NSObjectProtocol?

    init() {
        resetNavigationObserver = makeNavigationResetObserver()
    }

    deinit {
        if let observer = resetNavigationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    /// Navigate to chat with a user. Switches to the Messages tab before pushing ChatView.
    func navigateToChatWithUser(userId: String, userName: String) {
        tabCoordinator?.selectTab(5)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            tabCoordinator?.chatCoordinator.navigate(
                to: .chatDetail(otherUserId: userId, otherUserName: userName)
            )
        }
    }
}
