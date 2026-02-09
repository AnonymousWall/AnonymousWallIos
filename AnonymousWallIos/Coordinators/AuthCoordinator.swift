//
//  AuthCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for authentication flow navigation
//

import SwiftUI

/// Coordinator for managing authentication-related navigation
class AuthCoordinator: Coordinator {
    enum Destination: Hashable {
        case login
        case registration
        case forgotPassword
    }
    
    @Published var path = NavigationPath()
    @Published var showForgotPassword = false
    
    func navigate(to destination: Destination) {
        switch destination {
        case .login, .registration:
            path.append(destination)
        case .forgotPassword:
            showForgotPassword = true
        }
    }
    
    func dismissForgotPassword() {
        showForgotPassword = false
    }
}
