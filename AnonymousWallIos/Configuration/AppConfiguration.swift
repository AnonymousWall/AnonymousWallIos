//
//  AppConfiguration.swift
//  AnonymousWallIos
//
//  Environment-based configuration management
//

import Foundation

enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

struct AppConfiguration {
    // MARK: - Singleton
    
    static let shared = AppConfiguration()
    
    private init() {}
    
    // MARK: - Environment
    
    var environment: AppEnvironment {
        return AppEnvironment.current
    }
    
    // MARK: - API Configuration
    
    var apiBaseURL: String {
        switch environment {
        case .development:
            return "http://localhost:8080"
        case .staging:
            return "https://staging-api.anonymouswall.com"
        case .production:
            return "https://api.anonymouswall.com"
        }
    }
    
    var apiVersion: String {
        return "v1"
    }
    
    var fullAPIBaseURL: String {
        return "\(apiBaseURL)/api/\(apiVersion)"
    }
    
    // MARK: - Security
    
    var useHTTPS: Bool {
        switch environment {
        case .development:
            return false  // Allow HTTP for local development
        case .staging, .production:
            return true   // Require HTTPS for staging and production
        }
    }
    
    // MARK: - Feature Flags
    
    var enableLogging: Bool {
        switch environment {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
    
    var enableNetworkLogging: Bool {
        switch environment {
        case .development:
            return true
        case .staging, .production:
            return false
        }
    }
    
    // MARK: - Keychain
    
    var keychainService: String {
        return "com.anonymouswall.ios"
    }
    
    var authTokenKey: String {
        return "\(keychainService).authToken"
    }
    
    // MARK: - UserDefaults Keys
    
    struct UserDefaultsKeys {
        static let isAuthenticated = "isAuthenticated"
        static let userId = "userId"
        static let userEmail = "userEmail"
        static let userIsVerified = "userIsVerified"
        static let needsPasswordSetup = "needsPasswordSetup"
    }
}
