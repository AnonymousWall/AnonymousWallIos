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
    @StateObject private var appCoordinator: AppCoordinator

    init() {
        let authState = AuthState()
        _authState = StateObject(wrappedValue: authState)
        _appCoordinator = StateObject(wrappedValue: AppCoordinator(authState: authState))
    }

    var body: some Scene {
        WindowGroup {
            if authState.isAuthenticated {
                TabBarView(coordinator: appCoordinator.tabCoordinator)
                    .environmentObject(authState)
            } else {
                AuthenticationView(coordinator: appCoordinator.authCoordinator)
                    .environmentObject(authState)
            }
        }
    }
}
