//
//  AppCoordinator.swift
//  AnonymousWallIos
//
//  Main application coordinator
//

import SwiftUI

/// Main app coordinator managing high-level navigation
class AppCoordinator: ObservableObject {
    @Published var authCoordinator = AuthCoordinator()
    @Published var tabCoordinator = TabCoordinator()
    
    let authState: AuthState
    
    init(authState: AuthState) {
        self.authState = authState
    }
}
