//
//  MessageStore.swift
//  AnonymousWallIos
//
//  Thread-safe message storage using Actor model
//

import Foundation

/// Actor-based message store for thread-safe message management
actor MessageStore {
    
    // MARK: - Properties
    
    /// Messages stored by conversation partner's user ID
    private var messagesByConversation: [String: [Message]] = [:]
    
    /// Temporary messages pending server confirmation (by temporary ID)
    private var temporaryMessages: [String: TemporaryMessage] = [:]
    
    // MARK: - Message Operations
    
    /// Add a message to the store
    /// - Parameters:
    ///   - message: Message to add
    ///   - conversationUserId: The other user's ID in the conversation
    /// - Returns: True if message was added (not duplicate), false otherwise
    @discardableResult
    func addMessage(_ message: Message, for conversationUserId: String) -> Bool {
        var messages = messagesByConversation[conversationUserId] ?? []
        
        // Check for duplicates
        if messages.contains(where: { $0.id == message.id }) {
            return false
        }
        
        // Insert and sort by timestamp with stable ordering
        messages.append(message)
        messages.sort { msg1, msg2 in
            guard let date1 = msg1.timestamp, let date2 = msg2.timestamp else {
                return msg1.createdAt < msg2.createdAt
            }
            // Use timestamp comparison first
            if date1 != date2 {
                return date1 < date2
            }
            // Use message ID as tiebreaker for deterministic ordering
            return msg1.id < msg2.id
        }
        
        messagesByConversation[conversationUserId] = messages
        return true
    }
    
    /// Add multiple messages (merge operation)
    /// - Parameters:
    ///   - messages: Messages to add
    ///   - conversationUserId: The other user's ID
    /// - Returns: Number of new messages added
    @discardableResult
    func addMessages(_ messages: [Message], for conversationUserId: String) -> Int {
        var existingMessages = messagesByConversation[conversationUserId] ?? []
        
        // Create a set of existing IDs for O(1) lookup
        let existingIds = Set(existingMessages.map { $0.id })
        
        // Filter out duplicates
        let newMessages = messages.filter { !existingIds.contains($0.id) }
        
        if newMessages.isEmpty {
            return 0
        }
        
        // Append all new messages
        existingMessages.append(contentsOf: newMessages)
        
        // Sort once after all additions
        existingMessages.sort { msg1, msg2 in
            guard let date1 = msg1.timestamp, let date2 = msg2.timestamp else {
                return msg1.createdAt < msg2.createdAt
            }
            // Use timestamp comparison first
            if date1 != date2 {
                return date1 < date2
            }
            // Use message ID as tiebreaker for deterministic ordering
            return msg1.id < msg2.id
        }
        
        messagesByConversation[conversationUserId] = existingMessages
        return newMessages.count
    }
    
    /// Get all messages for a conversation
    /// - Parameter conversationUserId: The other user's ID
    /// - Returns: Array of messages sorted by timestamp (oldest first)
    func getMessages(for conversationUserId: String) -> [Message] {
        return messagesByConversation[conversationUserId] ?? []
    }
    
    /// Get the last message in a conversation
    /// - Parameter conversationUserId: The other user's ID
    /// - Returns: Most recent message or nil
    func getLastMessage(for conversationUserId: String) -> Message? {
        return messagesByConversation[conversationUserId]?.last
    }
    
    /// Update a message's read status
    /// - Parameters:
    ///   - messageId: Message ID to update
    ///   - conversationUserId: The other user's ID
    ///   - read: New read status
    func updateReadStatus(messageId: String, for conversationUserId: String, read: Bool) {
        guard var messages = messagesByConversation[conversationUserId] else { return }
        
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index] = messages[index].withReadStatus(read)
            messagesByConversation[conversationUserId] = messages
        }
    }
    
    /// Mark all messages from the other user as read (only messages where current user is receiver)
    /// - Parameters:
    ///   - conversationUserId: The other user's ID
    ///   - currentUserId: Current user's ID (to filter only received messages)
    func markAllAsRead(for conversationUserId: String, currentUserId: String) {
        guard var messages = messagesByConversation[conversationUserId] else { return }
        
        messages = messages.map { message in
            // Only mark as read if:
            // 1. Not already read
            // 2. Current user is the receiver (not the sender)
            if !message.readStatus && message.receiverId == currentUserId {
                return message.withReadStatus(true)
            }
            return message
        }
        
        messagesByConversation[conversationUserId] = messages
    }
    
    /// Update message local status (for optimistic UI)
    /// - Parameters:
    ///   - messageId: Message ID (or temporary ID)
    ///   - conversationUserId: The other user's ID
    ///   - status: New local status
    func updateLocalStatus(messageId: String, for conversationUserId: String, status: MessageStatus) {
        guard var messages = messagesByConversation[conversationUserId] else { return }
        
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index] = messages[index].withLocalStatus(status)
            messagesByConversation[conversationUserId] = messages
        }
    }
    
    /// Clear all messages for a conversation
    /// - Parameter conversationUserId: The other user's ID
    func clearMessages(for conversationUserId: String) {
        messagesByConversation.removeValue(forKey: conversationUserId)
    }
    
    /// Clear all messages
    func clearAll() {
        messagesByConversation.removeAll()
        temporaryMessages.removeAll()
    }
    
    // MARK: - Temporary Message Operations
    
    /// Add a temporary message (optimistic UI)
    /// - Parameter tempMessage: Temporary message
    func addTemporaryMessage(_ tempMessage: TemporaryMessage) {
        temporaryMessages[tempMessage.temporaryId] = tempMessage
    }
    
    /// Replace temporary message with confirmed message from server
    /// - Parameters:
    ///   - temporaryId: Temporary message ID
    ///   - confirmedMessage: Confirmed message from server
    ///   - conversationUserId: The other user's ID
    func confirmTemporaryMessage(temporaryId: String, confirmedMessage: Message, for conversationUserId: String) {
        // Remove temporary message
        temporaryMessages.removeValue(forKey: temporaryId)
        
        // Remove temporary message from conversation if it exists
        if var messages = messagesByConversation[conversationUserId] {
            messages.removeAll { $0.id == temporaryId }
            messagesByConversation[conversationUserId] = messages
        }
        
        // Add confirmed message
        addMessage(confirmedMessage, for: conversationUserId)
    }
    
    /// Get temporary message
    /// - Parameter temporaryId: Temporary message ID
    /// - Returns: Temporary message or nil
    func getTemporaryMessage(id temporaryId: String) -> TemporaryMessage? {
        return temporaryMessages[temporaryId]
    }
    
    /// Remove a temporary message (for failed sends)
    /// - Parameters:
    ///   - temporaryId: Temporary message ID
    ///   - conversationUserId: The other user's ID
    func removeTemporaryMessage(id temporaryId: String, for conversationUserId: String) {
        temporaryMessages.removeValue(forKey: temporaryId)
        
        // Also remove from conversation messages
        if var messages = messagesByConversation[conversationUserId] {
            messages.removeAll { $0.id == temporaryId }
            messagesByConversation[conversationUserId] = messages
        }
    }
    
    // MARK: - Pagination Support
    
    /// Get message count for a conversation
    /// - Parameter conversationUserId: The other user's ID
    /// - Returns: Number of messages
    func getMessageCount(for conversationUserId: String) -> Int {
        return messagesByConversation[conversationUserId]?.count ?? 0
    }
    
    /// Get messages newer than a specific timestamp
    /// - Parameters:
    ///   - conversationUserId: The other user's ID
    ///   - timestamp: ISO8601 timestamp string
    /// - Returns: Messages newer than timestamp
    func getMessagesNewerThan(timestamp: String, for conversationUserId: String) -> [Message] {
        guard let messages = messagesByConversation[conversationUserId] else { return [] }
        
        return messages.filter { $0.createdAt > timestamp }
    }
    
    // MARK: - Message Lookup
    
    /// Find conversation user ID for a given message ID
    /// - Parameter messageId: Message ID to find
    /// - Returns: Conversation user ID if found, nil otherwise
    func findConversation(forMessageId messageId: String) -> String? {
        for (conversationUserId, messages) in messagesByConversation {
            if messages.contains(where: { $0.id == messageId }) {
                return conversationUserId
            }
        }
        return nil
    }
}
