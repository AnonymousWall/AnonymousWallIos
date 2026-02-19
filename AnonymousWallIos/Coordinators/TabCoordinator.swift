//
//  TabCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for tab-based navigation
//

import SwiftUI

/// Coordinator for managing tab navigation and child coordinators
@MainActor
class TabCoordinator: ObservableObject {
    @Published var homeCoordinator = HomeCoordinator()
    @Published var campusCoordinator = CampusCoordinator()
    @Published var internshipCoordinator = InternshipCoordinator()
    @Published var marketplaceCoordinator = MarketplaceCoordinator()
    @Published var profileCoordinator = ProfileCoordinator()
    @Published var chatCoordinator = ChatCoordinator()
    @Published var selectedTab = 0
    
    init() {
        // Set up back-references for cross-coordinator navigation
        homeCoordinator.tabCoordinator = self
        campusCoordinator.tabCoordinator = self
        internshipCoordinator.tabCoordinator = self
        marketplaceCoordinator.tabCoordinator = self
    }
    
    func selectTab(_ index: Int) {
        selectedTab = index
    }
}
