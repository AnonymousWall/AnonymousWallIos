//
//  TabBarView.swift
//  AnonymousWallIos
//
//  Main TabBar navigation container
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var authState: AuthState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home (National Wall)
            HomeView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            // Tab 2: Campus Wall
            CampusView()
                .tabItem {
                    Label("Campus", systemImage: selectedTab == 1 ? "building.2.fill" : "building.2")
                }
                .tag(1)
            
            // Tab 3: Create
            CreatePostTabView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // Tab 4: Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)
            
            // Tab 5: Market (dummy)
            MarketView()
                .tabItem {
                    Label("Market", systemImage: selectedTab == 4 ? "cart.fill" : "cart")
                }
                .tag(4)
            
            // Tab 6: Internship (dummy)
            InternshipView()
                .tabItem {
                    Label("Internship", systemImage: selectedTab == 5 ? "briefcase.fill" : "briefcase")
                }
                .tag(5)
        }
        .accentColor(.primaryPurple)
        .onChange(of: selectedTab) { _, _ in
            HapticFeedback.selection()
        }
    }
}

#Preview {
    TabBarView()
        .environmentObject(AuthState())
}
