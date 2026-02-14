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
    private let preferencesStore: PreferencesStore
    
    init(loadPersistedState: Bool = true, preferencesStore: PreferencesStore = .shared) {
        self.keychainAuthTokenKey = config.authTokenKey
        self.preferencesStore = preferencesStore
        if loadPersistedState {
            // Load state synchronously by blocking on the async operation
            // This ensures AuthState is fully initialized before use
            Task { @MainActor in
                await self.loadAuthState()
            }
        }
    }
    
    func login(user: User, token: String) {
        self.currentUser = user
        self.authToken = token
        self.isAuthenticated = true
        // needsPasswordSetup is the inverse of passwordSet from the API
        // If passwordSet is nil or false, then we need password setup
        self.needsPasswordSetup = !(user.passwordSet ?? false)
        
        // Persist state asynchronously - fire-and-forget is acceptable here because:
        // 1. UI state (@Published properties) updates synchronously above
        // 2. UserDefaults writes are fast and rarely fail
        // 3. Next login/action will overwrite stale data if write fails
        Task {
            await saveAuthState()
        }
    }
    
    func updatePasswordSetupStatus(completed: Bool) {
        self.needsPasswordSetup = !completed
        // Persist asynchronously - fire-and-forget is safe for preference updates
        Task {
            await preferencesStore.setBool(needsPasswordSetup, forKey: AppConfiguration.UserDefaultsKeys.needsPasswordSetup)
        }
    }
    
    func markPasswordSetupShown() {
        self.hasShownPasswordSetup = true
    }
    
    func updateUser(_ user: User) {
        self.currentUser = user
        // Update password setup status
        let passwordSet = user.passwordSet ?? false
        self.needsPasswordSetup = !passwordSet
        
        // Update stored user data
        Task {
            await preferencesStore.saveBatch(
                strings: [
                    AppConfiguration.UserDefaultsKeys.userId: user.id,
                    AppConfiguration.UserDefaultsKeys.userEmail: user.email,
                    AppConfiguration.UserDefaultsKeys.userProfileName: user.profileName
                ],
                bools: [
                    AppConfiguration.UserDefaultsKeys.userIsVerified: user.isVerified,
                    AppConfiguration.UserDefaultsKeys.needsPasswordSetup: needsPasswordSetup
                ]
            )
        }
    }
    
    func logout() {
        self.currentUser = nil
        self.authToken = nil
        self.isAuthenticated = false
        self.needsPasswordSetup = false
        self.hasShownPasswordSetup = false
        self.showBlockedUserAlert = false
        // Clear persistence asynchronously - UI state cleared synchronously above
        Task {
            await clearAuthState()
        }
    }
    
    /// Handles blocked user response - logs out and shows alert
    func handleBlockedUser() {
        Logger.network.warning("Handling blocked user - logging out")
        logout()
        self.showBlockedUserAlert = true
    }
    
    /// Clears all persisted authentication state. Useful for testing.
    func clearPersistedState() {
        Task {
            await clearAuthState()
        }
    }
    
    private func saveAuthState() async {
        // Save non-sensitive data to PreferencesStore
        await preferencesStore.saveBatch(
            strings: [
                AppConfiguration.UserDefaultsKeys.userId: currentUser?.id,
                AppConfiguration.UserDefaultsKeys.userEmail: currentUser?.email,
                AppConfiguration.UserDefaultsKeys.userProfileName: currentUser?.profileName
            ],
            bools: [
                AppConfiguration.UserDefaultsKeys.isAuthenticated: isAuthenticated,
                AppConfiguration.UserDefaultsKeys.userIsVerified: currentUser?.isVerified ?? false,
                AppConfiguration.UserDefaultsKeys.needsPasswordSetup: needsPasswordSetup
            ]
        )
        
        // Save sensitive token to Keychain
        if let token = authToken {
            KeychainHelper.shared.save(token, forKey: keychainAuthTokenKey)
        }
    }
    
    private func loadAuthState() async {
        let keys = AppConfiguration.UserDefaultsKeys.self
        let result = await preferencesStore.loadBatch(
            stringKeys: [keys.userId, keys.userEmail, keys.userProfileName],
            boolKeys: [keys.isAuthenticated, keys.needsPasswordSetup, keys.userIsVerified]
        )
        
        // Update published properties on main actor
        await MainActor.run {
            self.isAuthenticated = result.bools[keys.isAuthenticated] ?? false
            self.needsPasswordSetup = result.bools[keys.needsPasswordSetup] ?? false
            
            // Load token from Keychain
            self.authToken = KeychainHelper.shared.get(keychainAuthTokenKey)
            
            if let userId = result.strings[keys.userId] as? String,
               let userEmail = result.strings[keys.userEmail] as? String {
                let isVerified = result.bools[keys.userIsVerified] ?? false
                let profileName = (result.strings[keys.userProfileName] as? String) ?? "Anonymous"
                // passwordSet is the inverse of needsPasswordSetup
                let passwordSet = !self.needsPasswordSetup
                self.currentUser = User(id: userId, email: userEmail, profileName: profileName, isVerified: isVerified, passwordSet: passwordSet, createdAt: "")
            }
        }
    }
    
    private func clearAuthState() async {
        // Clear PreferencesStore
        let keys = AppConfiguration.UserDefaultsKeys.self
        await preferencesStore.removeAll(forKeys: [
            keys.isAuthenticated,
            keys.userId,
            keys.userEmail,
            keys.userIsVerified,
            keys.needsPasswordSetup,
            keys.userProfileName
        ])
        
        // Clear Keychain
        KeychainHelper.shared.delete(keychainAuthTokenKey)
    }
}
