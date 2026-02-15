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
    /// Add a message to the store
    /// - Parameters:
    ///   - message: Message to add
    ///   - conversationUserId: The other user's ID
    /// - Returns: True if message was added (not duplicate), false otherwise
    @discardableResult
    func addMessage(_ message: Message, for conversationUserId: String) -> Bool {
        var messages = messagesByConversation[conversationUserId] ?? []
        
        // Check for duplicates by ID
        if messages.contains(where: { $0.id == message.id }) {
            Logger.chat.debug("MessageStore: Duplicate message \(message.id), skipping")
            return false
        }
        
        // Check if this might be a confirmation of a temporary message
        // (same content, sender, receiver, but within a reasonable time window)
        let recentTimeThreshold: TimeInterval = 10 // 10 seconds
        if let messageTimestamp = message.timestamp {
            if let tempMessageIndex = messages.firstIndex(where: { existingMsg in
                // Check if it's a temporary message (UUID format) with matching content
                existingMsg.id.count == 36 && // UUID length
                existingMsg.senderId == message.senderId &&
                existingMsg.receiverId == message.receiverId &&
                existingMsg.content == message.content &&
                existingMsg.id != message.id // Different IDs
            }) {
                // Found potential temporary message, check time difference
                if let tempTimestamp = messages[tempMessageIndex].timestamp {
                    let timeDiff = abs(messageTimestamp.timeIntervalSince(tempTimestamp))
                    if timeDiff < recentTimeThreshold {
                        Logger.chat.info("MessageStore: Replacing temporary message \(messages[tempMessageIndex].id) with confirmed \(message.id)")
                        messages.remove(at: tempMessageIndex)
                    }
                }
            }
        }
        
        // Log message details before insertion
        Logger.chat.info("MessageStore: Adding message \(message.id) for conversation \(conversationUserId)")
        Logger.chat.info("  - createdAt: \(message.createdAt)")
        Logger.chat.info("  - timestamp: \(message.timestamp?.description ?? "nil")")
        Logger.chat.info("  - senderId: \(message.senderId)")
        Logger.chat.info("  - receiverId: \(message.receiverId)")
        Logger.chat.info("  - Current message count: \(messages.count)")
        
        // Insert and sort by timestamp (always use parsed Date for reliable ordering)
        messages.append(message)
        messages.sort { msg1, msg2 in
            // Always parse to Date for consistent comparison
            guard let date1 = msg1.timestamp, let date2 = msg2.timestamp else {
                // Fallback to string comparison if parsing fails (should be rare)
                Logger.chat.warning("MessageStore: Failed to parse timestamp, using string comparison")
                return msg1.createdAt < msg2.createdAt
            }
            return date1 < date2
        }
        
        // Log sorted order
        Logger.chat.info("MessageStore: After sort, message count: \(messages.count)")
        for (index, msg) in messages.enumerated() {
            Logger.chat.debug("  [\(index)] id=\(msg.id) time=\(msg.createdAt) sender=\(msg.senderId)")
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
        var addedCount = 0
        for message in messages {
            if addMessage(message, for: conversationUserId) {
                addedCount += 1
            }
        }
        return addedCount
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
    
    /// Mark all messages from a user as read
    /// - Parameter conversationUserId: The other user's ID
    func markAllAsRead(for conversationUserId: String) {
        guard var messages = messagesByConversation[conversationUserId] else { return }
        
        messages = messages.map { message in
            if !message.readStatus {
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
}
