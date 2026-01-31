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
        userId: "userId",
        userEmail: "userEmail"
    )
    
    private let keychainAuthTokenKey = "com.anonymouswall.authToken"
    
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
        // Save non-sensitive data to UserDefaults
        UserDefaults.standard.set(isAuthenticated, forKey: userDefaultsKeys.isAuthenticated)
        UserDefaults.standard.set(currentUser?.id, forKey: userDefaultsKeys.userId)
        UserDefaults.standard.set(currentUser?.email, forKey: userDefaultsKeys.userEmail)
        
        // Save sensitive token to Keychain
        if let token = authToken {
            KeychainHelper.shared.save(token, forKey: keychainAuthTokenKey)
        }
    }
    
    private func loadAuthState() {
        isAuthenticated = UserDefaults.standard.bool(forKey: userDefaultsKeys.isAuthenticated)
        
        // Load token from Keychain
        authToken = KeychainHelper.shared.get(keychainAuthTokenKey)
        
        if let userId = UserDefaults.standard.string(forKey: userDefaultsKeys.userId),
           let userEmail = UserDefaults.standard.string(forKey: userDefaultsKeys.userEmail) {
            currentUser = User(id: userId, email: userEmail, createdAt: nil)
        }
    }
    
    private func clearAuthState() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.isAuthenticated)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.userId)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.userEmail)
        
        // Clear Keychain
        KeychainHelper.shared.delete(keychainAuthTokenKey)
    }
}
