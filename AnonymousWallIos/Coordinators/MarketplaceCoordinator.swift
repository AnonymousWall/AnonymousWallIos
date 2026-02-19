//
//  MarketplaceCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for marketplace feed navigation
//

import SwiftUI

/// Coordinator for managing marketplace feed navigation
@MainActor
class MarketplaceCoordinator: Coordinator {
    enum Destination: Hashable {
        case marketplaceDetail(MarketplaceItem)
    }

    @Published var path = NavigationPath()

    weak var tabCoordinator: TabCoordinator?

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func navigateToChatWithUser(userId: String, userName: String) {
        // Switch to Messages tab (tab 5), then navigate to chat after brief delay
        // to let ConversationsListView fully appear before pushing ChatView
        tabCoordinator?.selectTab(5)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            tabCoordinator?.chatCoordinator.navigate(
                to: .chatDetail(otherUserId: userId, otherUserName: userName)
            )
        }
    }
}
