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
    
    private let config = AppConfiguration.shared
    private let keychainAuthTokenKey: String
    
    init() {
        self.keychainAuthTokenKey = config.authTokenKey
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
        UserDefaults.standard.set(needsPasswordSetup, forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
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
        UserDefaults.standard.set(isAuthenticated, forKey: AppConfiguration.UserDefaultsKeys.isAuthenticated)
        UserDefaults.standard.set(currentUser?.id, forKey: AppConfiguration.UserDefaultsKeys.userId)
        UserDefaults.standard.set(currentUser?.email, forKey: AppConfiguration.UserDefaultsKeys.userEmail)
        UserDefaults.standard.set(currentUser?.isVerified, forKey: AppConfiguration.UserDefaultsKeys.userIsVerified)
        UserDefaults.standard.set(needsPasswordSetup, forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
        
        // Save sensitive token to Keychain
        if let token = authToken {
            KeychainHelper.shared.save(token, forKey: keychainAuthTokenKey)
        }
    }
    
    private func loadAuthState() {
        isAuthenticated = UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.isAuthenticated)
        needsPasswordSetup = UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
        
        // Load token from Keychain
        authToken = KeychainHelper.shared.get(keychainAuthTokenKey)
        
        if let userId = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userId),
           let userEmail = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userEmail) {
            let isVerified = UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.userIsVerified)
            currentUser = User(id: userId, email: userEmail, isVerified: isVerified, createdAt: "")
        }
    }
    
    private func clearAuthState() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.isAuthenticated)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.userId)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.userEmail)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.userIsVerified)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
        
        // Clear Keychain
        KeychainHelper.shared.delete(keychainAuthTokenKey)
    }
}
