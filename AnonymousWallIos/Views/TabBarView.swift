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
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Tab 2: Campus Wall
            CampusView()
                .tabItem {
                    Label("Campus", systemImage: "building.2.fill")
                }
                .tag(1)
            
            // Tab 3: Internship (dummy)
            InternshipView()
                .tabItem {
                    Label("Internship", systemImage: "briefcase.fill")
                }
                .tag(2)
            
            // Tab 4: Market (dummy)
            MarketView()
                .tabItem {
                    Label("Market", systemImage: "cart.fill")
                }
                .tag(3)
            
            // Tab 5: Create
            CreatePostTabView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(4)
            
            // Tab 6: Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(5)
        }
    }
}

#Preview {
    TabBarView()
        .environmentObject(AuthState())
}
