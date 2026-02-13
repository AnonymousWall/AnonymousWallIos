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
    @Published var hasShownPasswordSetup = false
    @Published var showBlockedUserAlert = false
    
    private let config = AppConfiguration.shared
    private let keychainAuthTokenKey: String
    
    init(loadPersistedState: Bool = true) {
        self.keychainAuthTokenKey = config.authTokenKey
        if loadPersistedState {
            loadAuthState()
        }
    }
    
    func login(user: User, token: String) {
        self.currentUser = user
        self.authToken = token
        self.isAuthenticated = true
        // needsPasswordSetup is the inverse of passwordSet from the API
        // If passwordSet is nil or false, then we need password setup
        self.needsPasswordSetup = !(user.passwordSet ?? false)
        saveAuthState()
    }
    
    func updatePasswordSetupStatus(completed: Bool) {
        self.needsPasswordSetup = !completed
        UserDefaults.standard.set(needsPasswordSetup, forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
    }
    
    func markPasswordSetupShown() {
        self.hasShownPasswordSetup = true
    }
    
    func updateUser(_ user: User) {
        self.currentUser = user
        // Update stored user data
        UserDefaults.standard.set(user.id, forKey: AppConfiguration.UserDefaultsKeys.userId)
        UserDefaults.standard.set(user.email, forKey: AppConfiguration.UserDefaultsKeys.userEmail)
        UserDefaults.standard.set(user.isVerified, forKey: AppConfiguration.UserDefaultsKeys.userIsVerified)
        UserDefaults.standard.set(user.profileName, forKey: AppConfiguration.UserDefaultsKeys.userProfileName)
        // Update password setup status
        let passwordSet = user.passwordSet ?? false
        self.needsPasswordSetup = !passwordSet
        UserDefaults.standard.set(needsPasswordSetup, forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
    }
    
    func logout() {
        self.currentUser = nil
        self.authToken = nil
        self.isAuthenticated = false
        self.needsPasswordSetup = false
        self.hasShownPasswordSetup = false
        self.showBlockedUserAlert = false
        clearAuthState()
    }
    
    /// Handles blocked user response - logs out and shows alert
    func handleBlockedUser() {
        Logger.network.warning("Handling blocked user - logging out")
        logout()
        self.showBlockedUserAlert = true
    }
    
    /// Clears all persisted authentication state. Useful for testing.
    func clearPersistedState() {
        clearAuthState()
    }
    
    private func saveAuthState() {
        // Save non-sensitive data to UserDefaults
        UserDefaults.standard.set(isAuthenticated, forKey: AppConfiguration.UserDefaultsKeys.isAuthenticated)
        UserDefaults.standard.set(currentUser?.id, forKey: AppConfiguration.UserDefaultsKeys.userId)
        UserDefaults.standard.set(currentUser?.email, forKey: AppConfiguration.UserDefaultsKeys.userEmail)
        UserDefaults.standard.set(currentUser?.profileName, forKey: AppConfiguration.UserDefaultsKeys.userProfileName)
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
            let profileName = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userProfileName) ?? "Anonymous"
            // passwordSet is the inverse of needsPasswordSetup
            let passwordSet = !needsPasswordSetup
            currentUser = User(id: userId, email: userEmail, profileName: profileName, isVerified: isVerified, passwordSet: passwordSet, createdAt: "")
        }
    }
    
    private func clearAuthState() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.isAuthenticated)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.userId)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.userEmail)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.userIsVerified)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.userProfileName)
        
        // Clear Keychain
        KeychainHelper.shared.delete(keychainAuthTokenKey)
    }
}
