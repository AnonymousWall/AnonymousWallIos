//
//  AuthState.swift
//  AnonymousWallIos
//
//  Authentication state management
//

import Foundation
import SwiftUI

class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private let userDefaultsKeys = (
        isAuthenticated: "isAuthenticated",
        authToken: "authToken",
        userId: "userId",
        userEmail: "userEmail"
    )
    
    init() {
        loadAuthState()
    }
    
    func login(user: User, token: String) {
        self.currentUser = user
        self.authToken = token
        self.isAuthenticated = true
        saveAuthState()
    }
    
    func logout() {
        self.currentUser = nil
        self.authToken = nil
        self.isAuthenticated = false
        clearAuthState()
    }
    
    private func saveAuthState() {
        UserDefaults.standard.set(isAuthenticated, forKey: userDefaultsKeys.isAuthenticated)
        UserDefaults.standard.set(authToken, forKey: userDefaultsKeys.authToken)
        UserDefaults.standard.set(currentUser?.id, forKey: userDefaultsKeys.userId)
        UserDefaults.standard.set(currentUser?.email, forKey: userDefaultsKeys.userEmail)
    }
    
    private func loadAuthState() {
        isAuthenticated = UserDefaults.standard.bool(forKey: userDefaultsKeys.isAuthenticated)
        authToken = UserDefaults.standard.string(forKey: userDefaultsKeys.authToken)
        
        if let userId = UserDefaults.standard.string(forKey: userDefaultsKeys.userId),
           let userEmail = UserDefaults.standard.string(forKey: userDefaultsKeys.userEmail) {
            currentUser = User(id: userId, email: userEmail, createdAt: nil)
        }
    }
    
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.isAuthenticated)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.authToken)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.userId)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.userEmail)
    }
}
