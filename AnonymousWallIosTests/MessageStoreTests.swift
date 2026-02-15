//
//  MessageStoreTests.swift
//  AnonymousWallIosTests
//
//  Tests for MessageStore actor - deduplication, ordering, thread safety
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct MessageStoreTests {
    
    // MARK: - Initialization Tests
    
    @Test func testMessageStoreInitializes() async throws {
        let store = MessageStore()
        let messages = await store.getMessages(for: "user1")
        #expect(messages.isEmpty)
    }
    
    // MARK: - Message Addition Tests
    
    @Test func testAddMessageReturnsTrue() async throws {
        let store = MessageStore()
        let message = createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2")
        
        let added = await store.addMessage(message, for: "user1")
        
        #expect(added == true)
        let messages = await store.getMessages(for: "user1")
        #expect(messages.count == 1)
        #expect(messages[0].id == "msg1")
    }
    
    @Test func testAddDuplicateMessageReturnsFalse() async throws {
        let store = MessageStore()
        let message = createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2")
        
        let added1 = await store.addMessage(message, for: "user1")
        let added2 = await store.addMessage(message, for: "user1")
        
        #expect(added1 == true)
        #expect(added2 == false)
        
        let messages = await store.getMessages(for: "user1")
        #expect(messages.count == 1)
    }
    
    @Test func testAddMultipleMessagesSortsCorrectly() async throws {
        let store = MessageStore()
        
        // Add messages out of order
        let message3 = createMockMessage(id: "msg3", senderId: "user1", receiverId: "user2", createdAt: "2026-02-15T12:03:00Z")
        let message1 = createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2", createdAt: "2026-02-15T12:01:00Z")
        let message2 = createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2", createdAt: "2026-02-15T12:02:00Z")
        
        await store.addMessage(message3, for: "user1")
        await store.addMessage(message1, for: "user1")
        await store.addMessage(message2, for: "user1")
        
        let messages = await store.getMessages(for: "user1")
        
        // Verify sorted by timestamp (oldest first)
        #expect(messages.count == 3)
        #expect(messages[0].id == "msg1")
        #expect(messages[1].id == "msg2")
        #expect(messages[2].id == "msg3")
    }
    
    @Test func testAddMessagesInBulk() async throws {
        let store = MessageStore()
        
        let messages = [
            createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2"),
            createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2"),
            createMockMessage(id: "msg3", senderId: "user1", receiverId: "user2")
        ]
        
        let addedCount = await store.addMessages(messages, for: "user1")
        
        #expect(addedCount == 3)
        let storedMessages = await store.getMessages(for: "user1")
        #expect(storedMessages.count == 3)
    }
    
    @Test func testAddMessagesInBulkWithDuplicates() async throws {
        let store = MessageStore()
        
        // Add initial message
        let message1 = createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2")
        await store.addMessage(message1, for: "user1")
        
        // Try to add batch including duplicate
        let messages = [
            createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2"), // Duplicate
            createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2"),
            createMockMessage(id: "msg3", senderId: "user1", receiverId: "user2")
        ]
        
        let addedCount = await store.addMessages(messages, for: "user1")
        
        #expect(addedCount == 2) // Only 2 new messages added
        let storedMessages = await store.getMessages(for: "user1")
        #expect(storedMessages.count == 3) // Total 3 messages
    }
    
    // MARK: - Message Retrieval Tests
    
    @Test func testGetLastMessage() async throws {
        let store = MessageStore()
        
        let message1 = createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2", createdAt: "2026-02-15T12:01:00Z")
        let message2 = createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2", createdAt: "2026-02-15T12:02:00Z")
        
        await store.addMessage(message1, for: "user1")
        await store.addMessage(message2, for: "user1")
        
        let lastMessage = await store.getLastMessage(for: "user1")
        
        #expect(lastMessage?.id == "msg2")
    }
    
    @Test func testGetMessagesNewerThan() async throws {
        let store = MessageStore()
        
        let message1 = createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2", createdAt: "2026-02-15T12:01:00Z")
        let message2 = createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2", createdAt: "2026-02-15T12:02:00Z")
        let message3 = createMockMessage(id: "msg3", senderId: "user1", receiverId: "user2", createdAt: "2026-02-15T12:03:00Z")
        
        await store.addMessages([message1, message2, message3], for: "user1")
        
        let newerMessages = await store.getMessagesNewerThan(timestamp: "2026-02-15T12:01:30Z", for: "user1")
        
        #expect(newerMessages.count == 2)
        #expect(newerMessages[0].id == "msg2")
        #expect(newerMessages[1].id == "msg3")
    }
    
    // MARK: - Read Status Tests
    
    @Test func testUpdateReadStatus() async throws {
        let store = MessageStore()
        let message = createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2", readStatus: false)
        
        await store.addMessage(message, for: "user1")
        await store.updateReadStatus(messageId: "msg1", for: "user1", read: true)
        
        let messages = await store.getMessages(for: "user1")
        #expect(messages[0].readStatus == true)
    }
    
    @Test func testMarkAllAsRead() async throws {
        let store = MessageStore()
        
        let messages = [
            createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2", readStatus: false),
            createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2", readStatus: false),
            createMockMessage(id: "msg3", senderId: "user1", receiverId: "user2", readStatus: false)
        ]
        
        await store.addMessages(messages, for: "user1")
        await store.markAllAsRead(for: "user1")
        
        let storedMessages = await store.getMessages(for: "user1")
        for message in storedMessages {
            #expect(message.readStatus == true)
        }
    }
    
    // MARK: - Local Status Tests
    
    @Test func testUpdateLocalStatus() async throws {
        let store = MessageStore()
        var message = createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2")
        message.localStatus = .sending
        
        await store.addMessage(message, for: "user1")
        await store.updateLocalStatus(messageId: "msg1", for: "user1", status: .sent)
        
        let messages = await store.getMessages(for: "user1")
        #expect(messages[0].localStatus == .sent)
    }
    
    // MARK: - Temporary Message Tests
    
    @Test func testAddTemporaryMessage() async throws {
        let store = MessageStore()
        let tempMessage = TemporaryMessage(
            temporaryId: "temp1",
            receiverId: "user2",
            content: "Test message",
            timestamp: Date()
        )
        
        await store.addTemporaryMessage(tempMessage)
        
        let retrieved = await store.getTemporaryMessage(id: "temp1")
        #expect(retrieved?.temporaryId == "temp1")
        #expect(retrieved?.content == "Test message")
    }
    
    @Test func testConfirmTemporaryMessage() async throws {
        let store = MessageStore()
        
        // Add temporary message
        let tempMessage = TemporaryMessage(
            temporaryId: "temp1",
            receiverId: "user2",
            content: "Test message",
            timestamp: Date()
        )
        await store.addTemporaryMessage(tempMessage)
        
        // Add temporary message to conversation for UI
        let displayMessage = tempMessage.toDisplayMessage(senderId: "user1")
        await store.addMessage(displayMessage, for: "user2")
        
        // Confirm with server message
        let confirmedMessage = createMockMessage(id: "server-msg-1", senderId: "user1", receiverId: "user2")
        await store.confirmTemporaryMessage(temporaryId: "temp1", confirmedMessage: confirmedMessage, for: "user2")
        
        // Verify temporary message removed
        let tempRetrieved = await store.getTemporaryMessage(id: "temp1")
        #expect(tempRetrieved == nil)
        
        // Verify confirmed message added
        let messages = await store.getMessages(for: "user2")
        #expect(messages.count == 1)
        #expect(messages[0].id == "server-msg-1")
    }
    
    @Test func testRemoveTemporaryMessage() async throws {
        let store = MessageStore()
        
        let tempMessage = TemporaryMessage(
            temporaryId: "temp1",
            receiverId: "user2",
            content: "Test message",
            timestamp: Date()
        )
        await store.addTemporaryMessage(tempMessage)
        
        // Add to conversation
        let displayMessage = tempMessage.toDisplayMessage(senderId: "user1")
        await store.addMessage(displayMessage, for: "user2")
        
        await store.removeTemporaryMessage(id: "temp1", for: "user2")
        
        let tempRetrieved = await store.getTemporaryMessage(id: "temp1")
        #expect(tempRetrieved == nil)
        
        let messages = await store.getMessages(for: "user2")
        #expect(messages.isEmpty)
    }
    
    // MARK: - Clear Operations Tests
    
    @Test func testClearMessages() async throws {
        let store = MessageStore()
        
        let messages = [
            createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2"),
            createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2")
        ]
        
        await store.addMessages(messages, for: "user1")
        await store.clearMessages(for: "user1")
        
        let storedMessages = await store.getMessages(for: "user1")
        #expect(storedMessages.isEmpty)
    }
    
    @Test func testClearAll() async throws {
        let store = MessageStore()
        
        await store.addMessage(createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2"), for: "user1")
        await store.addMessage(createMockMessage(id: "msg2", senderId: "user3", receiverId: "user4"), for: "user3")
        
        await store.clearAll()
        
        let messages1 = await store.getMessages(for: "user1")
        let messages2 = await store.getMessages(for: "user3")
        
        #expect(messages1.isEmpty)
        #expect(messages2.isEmpty)
    }
    
    // MARK: - Message Count Tests
    
    @Test func testGetMessageCount() async throws {
        let store = MessageStore()
        
        let messages = [
            createMockMessage(id: "msg1", senderId: "user1", receiverId: "user2"),
            createMockMessage(id: "msg2", senderId: "user1", receiverId: "user2"),
            createMockMessage(id: "msg3", senderId: "user1", receiverId: "user2")
        ]
        
        await store.addMessages(messages, for: "user1")
        
        let count = await store.getMessageCount(for: "user1")
        #expect(count == 3)
    }
    
    // MARK: - Test Helpers
    
    private func createMockMessage(
        id: String,
        senderId: String,
        receiverId: String,
        content: String = "Test message",
        readStatus: Bool = false,
        createdAt: String = "2026-02-15T12:00:00Z"
    ) -> Message {
        return Message(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            readStatus: readStatus,
            createdAt: createdAt
        )
    }
}
