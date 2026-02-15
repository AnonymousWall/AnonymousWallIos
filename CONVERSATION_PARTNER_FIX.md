# Critical Bug Fix: Conversation Partner Determination

## The Bug

### Scenario
When User1 sends a message to User2, the message travels through WebSocket and arrives at both users' apps.

### What Was Happening (BROKEN ❌)

```
User1 ChatView (conversation with User2)
  otherUserId = "user2"
  
User1 sends message "Hello"
  ↓
WebSocket broadcasts message:
  { id: "msg1", senderId: "user1", receiverId: "user2", content: "Hello" }
  ↓
ChatRepository receives message:
  conversationUserId = message.senderId = "user1"  ❌ WRONG!
  Stores in conversation["user1"]
  ↓
ChatViewModel checks:
  if conversationUserId == otherUserId
  if "user1" == "user2"  ❌ FALSE!
  Message IGNORED - not stored/displayed
  ↓
Result: Message doesn't appear in User1's ChatView with User2
        until user navigates away and back
```

### The Root Cause

In `ChatRepository.swift`, the code was:

```swift
// WRONG ❌
var messagePublisher: AnyPublisher<(Message, String), Never> {
    webSocketManager.messagePublisher
        .compactMap { [weak self] message -> (Message, String)? in
            guard let self = self else { return nil }
            let conversationUserId = message.senderId  // ❌ Always sender!
            return (message, conversationUserId)
        }
        .eraseToAnyPublisher()
}
```

**Problem**: Always using `message.senderId` means:
- When I receive a message FROM someone → Correct (conversation is with sender)
- When I receive MY OWN sent message back → WRONG (should be conversation with receiver)

## The Fix ✅

### Track Current User

```swift
// Added to ChatRepository
private var currentUserId: String?

func connect(token: String, userId: String) {
    self.currentUserId = userId  // ✅ Store current user
    webSocketManager.connect(token: token, userId: userId)
}
```

### Correct Conversation Partner Logic

```swift
// CORRECT ✅
var messagePublisher: AnyPublisher<(Message, String), Never> {
    webSocketManager.messagePublisher
        .compactMap { [weak self] message -> (Message, String)? in
            guard let self = self, let currentUserId = self.currentUserId else { return nil }
            
            // Determine conversation user ID (the other user in the conversation)
            let conversationUserId: String
            if message.senderId == currentUserId {
                // I sent this message → conversation is with the receiver
                conversationUserId = message.receiverId
            } else {
                // They sent this message → conversation is with the sender
                conversationUserId = message.senderId
            }
            
            return (message, conversationUserId)
        }
        .eraseToAnyPublisher()
}
```

### What Now Happens (FIXED ✅)

```
User1 ChatView (conversation with User2)
  otherUserId = "user2"
  
User1 sends message "Hello"
  ↓
WebSocket broadcasts message:
  { id: "msg1", senderId: "user1", receiverId: "user2", content: "Hello" }
  ↓
ChatRepository receives message:
  currentUserId = "user1"
  if message.senderId == currentUserId  ✅ TRUE
    conversationUserId = message.receiverId = "user2"  ✅ CORRECT!
  Stores in conversation["user2"]
  ↓
ChatViewModel checks:
  if conversationUserId == otherUserId
  if "user2" == "user2"  ✅ TRUE!
  Message PROCESSED - stored and displayed immediately
  ↓
Result: ✅ Message appears instantly in correct order
        ✅ Read status updates in real-time
```

## Impact of This Fix

### Before Fix ❌
1. Send message → doesn't appear in your own ChatView
2. Navigate to ConversationList → back to ChatView → message appears
3. Receive message → appears but marked as unread
4. Navigate away and back → read status updates

### After Fix ✅
1. Send message → ✅ appears immediately in correct chronological order
2. Receive message → ✅ appears immediately and marked as read (if view active)
3. No navigation needed → ✅ everything updates in real-time
4. Read receipts → ✅ sent immediately

## Technical Details

### Message Flow (Fixed)

```
┌─────────────────────────────────────────────────────┐
│  User1 sends to User2                               │
├─────────────────────────────────────────────────────┤
│                                                      │
│  WebSocket Message:                                 │
│    senderId: "user1"                                │
│    receiverId: "user2"                              │
│                                                      │
│  ┌──────────────────┐      ┌──────────────────┐   │
│  │  User1's App     │      │  User2's App     │   │
│  │  currentUserId:  │      │  currentUserId:  │   │
│  │  "user1"         │      │  "user2"         │   │
│  └────────┬─────────┘      └────────┬─────────┘   │
│           │                          │              │
│  senderId == currentUserId    senderId != current  │
│  "user1" == "user1" ✅        "user1" != "user2"   │
│           │                          │              │
│  conversation =              conversation =         │
│  receiverId                  senderId               │
│  = "user2" ✅                = "user1" ✅          │
│           │                          │              │
│  Stores in                   Stores in             │
│  conversation["user2"]       conversation["user1"] │
│           │                          │              │
│  ChatView with User2 ✅      ChatView with User1 ✅│
│  Shows message!              Shows message!         │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Storage Logic (Fixed)

```
MessageStore structure:
  messagesByConversation: [String: [Message]]
  
Key = "otherUserId" (the person you're chatting with)

User1's perspective:
  Conversation with User2 → key = "user2"
  All messages in this conversation stored here
  
When User1 sends to User2:
  ❌ OLD: Stored in ["user1"] → WRONG bucket!
  ✅ NEW: Stored in ["user2"] → CORRECT bucket!
  
When User2 sends to User1:
  Both old and new: Stored in ["user2"] → Correct!
```

## Files Changed

### ChatRepository.swift
- Added `currentUserId: String?` property
- Updated `connect()` to store currentUserId
- Fixed `messagePublisher` with correct partner logic
- Fixed `setupWebSocketObservers()` with same logic
- Added debug logging

## Verification

Run the app and:
1. Open ChatView between User1 and User2
2. User1 sends "test1"
3. Verify: Message appears immediately in User1's view
4. Verify: Message appears immediately in User2's view (if open)
5. Verify: Read status updates if User2 is viewing
6. No need to navigate away and back!

## Related Issues Fixed

This fix also resolves:
- ✅ Message ordering issues
- ✅ Read status not updating
- ✅ Unread badges showing incorrectly
- ✅ Need to refresh by navigating away

All these issues stemmed from messages being stored in the wrong conversation bucket.
