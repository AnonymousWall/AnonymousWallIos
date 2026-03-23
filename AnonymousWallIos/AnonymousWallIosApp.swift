//
//  AnonymousWallIosApp.swift
//  AnonymousWallIos
//
//  Created by Ziyi Huang on 1/30/26.
//

import SwiftUI

@main
struct AnonymousWallIosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authState = AuthState()
    @StateObject private var appCoordinator: AppCoordinator
    @StateObject private var blockViewModel = BlockViewModel()
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared
    @State private var tokenRefreshTimer: Timer?

    init() {
        let authState = AuthState()
        let appCoordinator = AppCoordinator(authState: authState)
        _authState = StateObject(wrappedValue: authState)
        _appCoordinator = StateObject(wrappedValue: appCoordinator)

        // Configure synchronously — these are plain property assignments,
        // no async work needed. Avoids a race window on cold launch where
        // the first network requests fire before the Task body executes.
        NetworkClient.shared.configureBlockedUserHandler { [weak authState] in
            authState?.handleBlockedUser()
        }
        NetworkClient.shared.configureUnauthorizedHandler { [weak authState, weak appCoordinator] in
            appCoordinator?.disconnectChat()
            authState?.logout(revokeServerToken: false)
        }
        NetworkClient.shared.configureTokenRefreshHandler { [weak authState] newToken in
            authState?.authToken = newToken
            NotificationCenter.default.post(
                name: .tokenRefreshed,
                object: nil,
                userInfo: ["token": newToken]
            )
        }

        configureAppAppearance()
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authState.isAuthenticated {
                    TabBarView(coordinator: appCoordinator.tabCoordinator)
                        .environmentObject(authState)
                        .environmentObject(blockViewModel)
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
                if authState.isAuthenticated {
                    appCoordinator.reconnectChatForForeground()
                    Task {
                        await NotificationService.shared.requestPermissionAndRegister()
                        await appCoordinator.tabCoordinator.notificationsViewModel
                            .fetchUnreadCount(authState: authState)
                    }
                    // Proactively refresh immediately on foreground — the token may be
                    // close to or past expiry after a long background stint. This avoids
                    // a burst of 401s on the first wave of requests when the user returns.
                    Task { [weak authState, weak appCoordinator] in
                        let capturedAuthState = authState
                        let capturedCoordinator = appCoordinator
                        let result = await NetworkClient.shared.refreshAccessToken()
                        if result == false {
                            await MainActor.run {
                                capturedCoordinator?.disconnectChat()
                                capturedAuthState?.logout(revokeServerToken: false)
                            }
                        }
                    }
                    tokenRefreshTimer?.invalidate()
                    tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: 13 * 60, repeats: true) { [weak authState, weak appCoordinator] _ in
                        let capturedAuthState = authState
                        let capturedCoordinator = appCoordinator
                        Task {
                            let result = await NetworkClient.shared.refreshAccessToken()
                            if result == false {
                                await MainActor.run {
                                    capturedCoordinator?.disconnectChat()
                                    capturedAuthState?.logout(revokeServerToken: false)
                                }
                            }
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: .resetNavigation, object: nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                if authState.isAuthenticated {
                    appCoordinator.disconnectChatForBackground()
                    tokenRefreshTimer?.invalidate()
                    tokenRefreshTimer = nil
                }
            }
            .onChange(of: authState.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    tokenRefreshTimer?.invalidate()
                    tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: 13 * 60, repeats: true) { [weak authState, weak appCoordinator] _ in
                        let capturedAuthState = authState
                        let capturedCoordinator = appCoordinator
                        Task {
                            let result = await NetworkClient.shared.refreshAccessToken()
                            if result == false {
                                await MainActor.run {
                                    capturedCoordinator?.disconnectChat()
                                    capturedAuthState?.logout(revokeServerToken: false)
                                }
                            }
                        }
                    }
                } else {
                    tokenRefreshTimer?.invalidate()
                    tokenRefreshTimer = nil
                }
            }
            .onChange(of: deepLinkHandler.pendingDestination) { _, destination in
                guard let destination, authState.isAuthenticated else { return }
                appCoordinator.navigate(to: destination)
                deepLinkHandler.consume()
            }
        }
    }

    private func configureAppAppearance() {
        // Tab bar: app background, no separator, purple selected tint
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.appBackground)
        tabBarAppearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(Color.accentPurple)

        // Navigation bar: app background, primary text
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.appBackground)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.textPrimary)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.textPrimary)]
        navBarAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.accentPurple)
    }
}
