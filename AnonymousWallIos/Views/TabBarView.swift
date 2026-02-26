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
            // Tab 1: Home (National Wall)
            HomeView(coordinator: coordinator.homeCoordinator)
                .tabItem {
                    Label("Home", systemImage: coordinator.selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            // Tab 2: Campus Wall
            CampusView(coordinator: coordinator.campusCoordinator)
                .tabItem {
                    Label("Campus", systemImage: coordinator.selectedTab == 1 ? "building.2.fill" : "building.2")
                }
                .tag(1)
            
            // Tab 3: Create
            CreatePostTabView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // Tab 4: Internship
            InternshipView(coordinator: coordinator.internshipCoordinator)
                .tabItem {
                    Label("Internship", systemImage: coordinator.selectedTab == 3 ? "briefcase.fill" : "briefcase")
                }
                .tag(3)
            
            // Tab 5: Market
            MarketView(coordinator: coordinator.marketplaceCoordinator)
                .tabItem {
                    Label("Market", systemImage: coordinator.selectedTab == 4 ? "cart.fill" : "cart")
                }
                .tag(4)
            
            // Tab 6: Messages
            MessagesView(coordinator: coordinator.chatCoordinator)
                .tabItem {
                    Label("Messages", systemImage: coordinator.selectedTab == 5 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                }
                .tag(5)
            
            // Tab 7: Profile
            ProfileView(coordinator: coordinator.profileCoordinator)
                .tabItem {
                    Label("Profile", systemImage: coordinator.selectedTab == 6 ? "person.fill" : "person")
                }
                .tag(6)
        }
        .accentColor(.primaryPurple)
        .animation(.easeInOut(duration: 0.2), value: coordinator.selectedTab)
        .onChange(of: coordinator.selectedTab) { _, _ in
            HapticFeedback.selection()
        }
    }
}

#Preview {
    TabBarView(coordinator: TabCoordinator())
        .environmentObject(AuthState())
}
