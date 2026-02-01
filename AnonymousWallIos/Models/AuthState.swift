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
    @Published var needsPasswordSetup = false
    
    private let userDefaultsKeys = (
        isAuthenticated: "isAuthenticated",
        userId: "userId",
        userEmail: "userEmail",
        userIsVerified: "userIsVerified",
        needsPasswordSetup: "needsPasswordSetup"
    )
    
    private let keychainAuthTokenKey = "com.anonymouswall.authToken"
    
    init() {
        loadAuthState()
    }
    
    func login(user: User, token: String, needsPasswordSetup: Bool = false) {
        self.currentUser = user
        self.authToken = token
        self.isAuthenticated = true
        self.needsPasswordSetup = needsPasswordSetup
        saveAuthState()
    }
    
    func updatePasswordSetupStatus(completed: Bool) {
        self.needsPasswordSetup = !completed
        UserDefaults.standard.set(needsPasswordSetup, forKey: userDefaultsKeys.needsPasswordSetup)
    }
    
    func logout() {
        self.currentUser = nil
        self.authToken = nil
        self.isAuthenticated = false
        self.needsPasswordSetup = false
        clearAuthState()
    }
    
    private func saveAuthState() {
        // Save non-sensitive data to UserDefaults
        UserDefaults.standard.set(isAuthenticated, forKey: userDefaultsKeys.isAuthenticated)
        UserDefaults.standard.set(currentUser?.id, forKey: userDefaultsKeys.userId)
        UserDefaults.standard.set(currentUser?.email, forKey: userDefaultsKeys.userEmail)
        UserDefaults.standard.set(currentUser?.isVerified, forKey: userDefaultsKeys.userIsVerified)
        UserDefaults.standard.set(needsPasswordSetup, forKey: userDefaultsKeys.needsPasswordSetup)
        
        // Save sensitive token to Keychain
        if let token = authToken {
            KeychainHelper.shared.save(token, forKey: keychainAuthTokenKey)
        }
    }
    
    private func loadAuthState() {
        isAuthenticated = UserDefaults.standard.bool(forKey: userDefaultsKeys.isAuthenticated)
        needsPasswordSetup = UserDefaults.standard.bool(forKey: userDefaultsKeys.needsPasswordSetup)
        
        // Load token from Keychain
        authToken = KeychainHelper.shared.get(keychainAuthTokenKey)
        
        if let userId = UserDefaults.standard.string(forKey: userDefaultsKeys.userId),
           let userEmail = UserDefaults.standard.string(forKey: userDefaultsKeys.userEmail) {
            let isVerified = UserDefaults.standard.bool(forKey: userDefaultsKeys.userIsVerified)
            currentUser = User(id: userId, email: userEmail, isVerified: isVerified, createdAt: "")
        }
    }
    
    private func clearAuthState() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.isAuthenticated)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.userId)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.userEmail)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.userIsVerified)
        UserDefaults.standard.removeObject(forKey: userDefaultsKeys.needsPasswordSetup)
        
        // Clear Keychain
        KeychainHelper.shared.delete(keychainAuthTokenKey)
    }
}
