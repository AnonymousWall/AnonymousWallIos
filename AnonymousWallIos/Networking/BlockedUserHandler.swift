//
//  BlockedUserHandler.swift
//  AnonymousWallIos
//
//  Global handler for blocked user (403) responses
//

import Foundation

/// Protocol for handling blocked user responses
protocol BlockedUserHandlerProtocol {
    func handleBlockedUser()
}

/// Thread-safe handler for blocked user (HTTP 403) responses
/// Ensures logout is only triggered once even with concurrent 403 responses
@MainActor
class BlockedUserHandler: BlockedUserHandlerProtocol {
    
    // MARK: - Properties
    
    private var isHandlingBlock = false
    private let logger = Logger.network
    
    /// Closure to execute logout and navigation
    var onBlockedUser: (() -> Void)?
    
    // MARK: - Public Methods
    
    /// Handles a blocked user response
    /// - Note: Thread-safe and prevents duplicate executions
    func handleBlockedUser() {
        // Prevent duplicate handling
        guard !isHandlingBlock else {
            logger.debug("Blocked user already being handled, skipping duplicate")
            return
        }
        
        isHandlingBlock = true
        logger.warning("User account blocked - initiating logout")
        
        // Execute the blocking handling closure
        onBlockedUser?()
    }
    
    /// Resets the handler state (useful for testing)
    func reset() {
        isHandlingBlock = false
    }
}
