//
//  PreferencesStore.swift
//  AnonymousWallIos
//
//  Actor-based thread-safe wrapper for UserDefaults persistence
//

import Foundation

/// Thread-safe actor for managing UserDefaults persistence
/// Centralizes all UserDefaults access to ensure concurrency safety
actor PreferencesStore {
    
    // MARK: - Singleton
    
    static let shared = PreferencesStore()
    
    private let userDefaults: UserDefaults
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - String Operations
    
    func getString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    func setString(_ value: String?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    // MARK: - Bool Operations
    
    func getBool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    func setBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    // MARK: - Batch Operations
    
    /// Saves multiple string and bool values atomically
    func saveBatch(strings: [String: String?], bools: [String: Bool]) {
        for (key, value) in strings {
            userDefaults.set(value, forKey: key)
        }
        for (key, value) in bools {
            userDefaults.set(value, forKey: key)
        }
    }
    
    /// Loads multiple values in one call
    func loadBatch(stringKeys: [String], boolKeys: [String]) -> (strings: [String: String?], bools: [String: Bool]) {
        var strings: [String: String?] = [:]
        var bools: [String: Bool] = [:]
        
        for key in stringKeys {
            strings[key] = userDefaults.string(forKey: key)
        }
        for key in boolKeys {
            bools[key] = userDefaults.bool(forKey: key)
        }
        
        return (strings, bools)
    }
    
    // MARK: - Remove Operations
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func removeAll(forKeys keys: [String]) {
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    // MARK: - Testing Support
    
    /// Creates a test instance with custom UserDefaults for isolated testing
    static func test(userDefaults: UserDefaults = UserDefaults(suiteName: "test")!) -> PreferencesStore {
        return PreferencesStore(userDefaults: userDefaults)
    }
}
