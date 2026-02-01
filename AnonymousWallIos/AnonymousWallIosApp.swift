//
//  AnonymousWallIosApp.swift
//  AnonymousWallIos
//
//  Created by Ziyi Huang on 1/30/26.
//

import SwiftUI

@main
struct AnonymousWallIosApp: App {
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            if authState.isAuthenticated {
                TabBarView()
                    .environmentObject(authState)
            } else {
                AuthenticationView()
                    .environmentObject(authState)
            }
        }
    }
}
