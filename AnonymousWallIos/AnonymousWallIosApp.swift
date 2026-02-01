//
//  AnonymousWallIosApp.swift
//  AnonymousWallIos
//
//  Created by Ziyi Huang on 1/30/26.
//

import SwiftUI
import SwiftData

@main
struct AnonymousWallIosApp: App {
    @StateObject private var authState = AuthState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authState.isAuthenticated {
                WallView()
                    .environmentObject(authState)
            } else {
                AuthenticationView()
                    .environmentObject(authState)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
