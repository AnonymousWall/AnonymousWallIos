//
//  TabBarView.swift
//  AnonymousWallIos
//
//  Main TabBar navigation container
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var authState: AuthState
    @ObservedObject var coordinator: TabCoordinator
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Tab 0: Home (National Wall)
            HomeView(coordinator: coordinator.homeCoordinator)
                .tabItem {
                    Label("Home", systemImage: coordinator.selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            // Tab 1: Campus Wall
            CampusView(coordinator: coordinator.campusCoordinator)
                .tabItem {
                    Label("Campus", systemImage: coordinator.selectedTab == 1 ? "building.2.fill" : "building.2")
                }
                .tag(1)
            
            // Tab 2: Create
            CreatePostTabView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // Tab 3: Internship
            InternshipView(coordinator: coordinator.internshipCoordinator)
                .tabItem {
                    Label("Internship", systemImage: coordinator.selectedTab == 3 ? "briefcase.fill" : "briefcase")
                }
                .tag(3)
            
            // Tab 4: Market
            MarketView(coordinator: coordinator.marketplaceCoordinator)
                .tabItem {
                    Label("Market", systemImage: coordinator.selectedTab == 4 ? "cart.fill" : "cart")
                }
                .tag(4)
            
            // Tab 5: Messages
            MessagesView(coordinator: coordinator.chatCoordinator)
                .tabItem {
                    Label("Messages", systemImage: coordinator.selectedTab == 5 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                }
                .tag(5)
            
            // Tab 6: Notifications
            NotificationInboxView(coordinator: coordinator.notificationCoordinator)
                .tabItem {
                    Label("Notifications", systemImage: coordinator.selectedTab == 6 ? "bell.fill" : "bell")
                }
                .badge(coordinator.notificationUnreadCount > 0 ? coordinator.notificationUnreadCount : nil)
                .tag(6)
            
            // Tab 7: Profile
            ProfileView(coordinator: coordinator.profileCoordinator)
                .tabItem {
                    Label("Profile", systemImage: coordinator.selectedTab == 7 ? "person.fill" : "person")
                }
                .tag(7)
        }
        .accentColor(.accentPurple)
        .animation(.easeInOut(duration: 0.2), value: coordinator.selectedTab)
        .onChange(of: coordinator.selectedTab) { _, _ in
            HapticFeedback.selection()
        }
    }
}

#Preview {
    TabBarView(coordinator: TabCoordinator())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}
