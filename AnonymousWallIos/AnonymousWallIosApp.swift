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
        
        // Configure blocked user handler at app startup
        Task { @MainActor in
            NetworkClient.shared.configureBlockedUserHandler {
                authState.handleBlockedUser()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authState.isAuthenticated {
                    TabBarView(coordinator: appCoordinator.tabCoordinator)
                        .environmentObject(authState)
                } else {
                    AuthenticationView(coordinator: appCoordinator.authCoordinator)
                        .environmentObject(authState)
                }
            }
            .alert("Account Blocked", isPresented: $authState.showBlockedUserAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your account has been blocked. Please contact support.")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Reset all navigation stacks to root when the app becomes active
                // without a valid session, preventing a stale/frozen navigation state
                // (e.g. ChatView stuck while backend is down).
                if !authState.isAuthenticated {
                    NotificationCenter.default.post(name: .resetNavigation, object: nil)
                }
            }
        }
    }
}
