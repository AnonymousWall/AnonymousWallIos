//
//  TabCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for tab-based navigation
//

import SwiftUI

/// Coordinator for managing tab navigation and child coordinators
class TabCoordinator: ObservableObject {
    @Published var homeCoordinator = HomeCoordinator()
    @Published var campusCoordinator = CampusCoordinator()
    @Published var profileCoordinator = ProfileCoordinator()
    @Published var chatCoordinator = ChatCoordinator()
    @Published var selectedTab = 0
    
    func selectTab(_ index: Int) {
        selectedTab = index
    }
}
