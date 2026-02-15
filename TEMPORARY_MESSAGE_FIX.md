# Temporary Message Replacement Fix

## The Problem

When User2 sends a message while in ChatView:

1. **Optimistic Message Created**
   ```
   Temp Message:
     id: "550e8400-e29b-41d4-a716-446655440000" (UUID)
     timestamp: 2026-02-15T22:30:00.100Z (client time)
     content: "test2"
     senderId: "user2"
   ```

2. **Message Sent via WebSocket**
   ```
   Sent to server via WebSocket
   ```

3. **Server Confirms**
   ```
   Confirmed Message (via WebSocket):
     id: "msg_12345" (server ID)
     timestamp: 2026-02-15T22:30:00.500Z (server time)
     content: "test2"
     senderId: "user2"
   ```

4. **PROBLEM: Both Messages Exist!**
   ```
   MessageStore now has:
     [0] "test1" - 22:29:00 (from User1)
     [1] "test2" - 22:30:00.100 (temp message)
     [2] "test2" - 22:30:00.500 (confirmed)
   
   When sorted by timestamp:
     [0] "test1" - 22:29:00
     [1] "test2" - 22:30:00.100 (temp - wrong!)
     [2] "test2" - 22:30:00.500 (real)
   ```

5. **User Sees Wrong Order**
   - User2's temporary message appears before the confirmed one
   - When User1 sends a new message, it goes between them
   - Chaos ensues!

## The Solution

### Smart Deduplication in MessageStore

```swift
func addMessage(_ message: Message, for conversationUserId: String) -> Bool {
    var messages = messagesByConversation[conversationUserId] ?? []
    
    // Check for duplicates by ID
    if messages.contains(where: { $0.id == message.id }) {
        return false
    }
    
    // NEW: Check if this is confirming a temporary message
    let recentTimeThreshold: TimeInterval = 10 // 10 seconds
    if let messageTimestamp = message.timestamp {
        if let tempMessageIndex = messages.firstIndex(where: { existingMsg in
            // Detect temporary message (UUID format)
            existingMsg.id.count == 36 &&
            existingMsg.senderId == message.senderId &&
            existingMsg.receiverId == message.receiverId &&
            existingMsg.content == message.content &&
            existingMsg.id != message.id
        }) {
            // Check time difference
            if let tempTimestamp = messages[tempMessageIndex].timestamp {
                let timeDiff = abs(messageTimestamp.timeIntervalSince(tempTimestamp))
                if timeDiff < recentTimeThreshold {
                    // Replace temporary with confirmed
                    messages.remove(at: tempMessageIndex)
                }
            }
        }
    }
    
    // Add message and sort
    messages.append(message)
    messages.sort { $0.timestamp! < $1.timestamp! }
    
    messagesByConversation[conversationUserId] = messages
    return true
}
```

### How It Works

1. **Temporary Message Added** (on send)
   ```
   MessageStore:
     [0] "test1" - 22:29:00 (User1)
     [1] "test2" - 22:30:00.100 (User2 temp)
   ```

2. **Server Confirmation Arrives** (via WebSocket)
   ```
   Incoming: "test2" with id="msg_12345" timestamp=22:30:00.500
   
   Detection Logic:
     ✓ Same content: "test2"
     ✓ Same sender: "user2"  
     ✓ Same receiver: "user1"
     ✓ Different IDs: UUID vs server ID
     ✓ Time diff: 0.4 seconds < 10 seconds
   
   Action: Remove temporary message
   ```

3. **Result: Clean Store**
   ```
   MessageStore:
     [0] "test1" - 22:29:00 (User1)
     [1] "test2" - 22:30:00.500 (User2 confirmed)
   
   ✅ Correct chronological order!
   ```

## Additional Fixes

### 1. Fixed `withReadStatus` to Preserve Local Status

**Before:**
```swift
func withReadStatus(_ read: Bool) -> Message {
    var copy = self
    copy.localStatus = read ? .read : .delivered
    return Message(...) // Creates new message with default localStatus!
}
```

**After:**
```swift
func withReadStatus(_ read: Bool) -> Message {
    var newMessage = Message(...)
    newMessage.localStatus = read ? .read : self.localStatus
    return newMessage
}
```

### 2. Added Comprehensive Logging

```swift
Logger.chat.info("MessageStore: Adding message \(message.id)")
Logger.chat.info("  - createdAt: \(message.createdAt)")
Logger.chat.info("  - timestamp: \(message.timestamp)")
Logger.chat.info("  - senderId: \(message.senderId)")

// After sorting
for (index, msg) in messages.enumerated() {
    Logger.chat.debug("  [\(index)] id=\(msg.id) time=\(msg.createdAt)")
}
```

## Testing Scenarios

### Scenario 1: User2 Sends While in ChatView

**Steps:**
1. User1 and User2 both in ChatView
2. User2 sends "hello"

**Expected:**
- ✅ User2 sees "hello" immediately (optimistic)
- ✅ Server confirms within ~500ms
- ✅ Temporary message replaced seamlessly
- ✅ User1 receives "hello" in correct order
- ✅ No duplicate messages

**Logs:**
```
MessageStore: Adding message 550e8400-... (temp)
  - timestamp: 2026-02-15T22:30:00.100Z
  [0] test1 - 22:29:00
  [1] hello - 22:30:00.100

WebSocket: Own message sent to user1
MessageStore: Replacing temporary message 550e8400-... with confirmed msg_12345
MessageStore: Adding message msg_12345
  - timestamp: 2026-02-15T22:30:00.500Z
  [0] test1 - 22:29:00
  [1] hello - 22:30:00.500
```

### Scenario 2: Rapid Message Exchange

**Steps:**
1. User1 sends "msg1"
2. User2 sends "msg2"
3. User1 sends "msg3"

**Expected:**
- ✅ All messages in chronological order
- ✅ Each temporary message replaced
- ✅ No duplicates or gaps

## Why This Matters

### Before Fix
```
Conversation View:
  [User1] msg1 ✓
  [User2] msg2 ✓ (temp - wrong timestamp)
  [User1] msg3 ✓
  [User2] msg2 ✓ (confirmed - right timestamp)
  
❌ User2's message appears twice
❌ Wrong chronological order
❌ Confusing UX
```

### After Fix
```
Conversation View:
  [User1] msg1 ✓
  [User2] msg2 ✓ (seamlessly replaced)
  [User1] msg3 ✓
  
✅ Each message appears once
✅ Perfect chronological order
✅ Smooth UX
```

## Edge Cases Handled

1. **Time Threshold**: Only matches within 10 seconds
   - Prevents false matches with old messages
   
2. **Content Matching**: Must match exactly
   - Prevents replacing wrong messages
   
3. **Sender/Receiver Matching**: Must match both
   - Ensures correct conversation context
   
4. **UUID Detection**: Checks ID length == 36
   - Only replaces temporary messages, not confirmed ones
   
5. **Different IDs**: Ensures IDs are different
   - Prevents removing the same message

## Performance Impact

- ✅ Minimal: O(n) scan of existing messages
- ✅ Only scans when adding new message
- ✅ Typically <10 messages to scan
- ✅ No noticeable performance impact

## Future Improvements

Possible enhancements:
1. Track temporary message IDs explicitly
2. Use content hash for faster matching
3. Batch replacements for multiple messages
4. Server-side echo with temp ID reference

But current solution is sufficient for production use.
