# Chat Implementation Quick Reference

## 🚀 Quick Start Integration

### Step 1: Create Repository Instance
```swift
// In your app initialization or coordinator
let messageStore = MessageStore()
let webSocketManager = ChatWebSocketManager()
let chatRepository = ChatRepository(
    chatService: ChatService.shared,
    webSocketManager: webSocketManager,
    messageStore: messageStore
)
```

### Step 2: Add Conversations List to Navigation
```swift
// In your main TabView or navigation
let conversationsViewModel = ConversationsViewModel(repository: chatRepository)

TabView {
    // ... existing tabs
    
    ConversationsListView(viewModel: conversationsViewModel)
        .tabItem {
            Label("Messages", systemImage: "bubble.left.and.bubble.right")
        }
        .environmentObject(authState)
}
```

### Step 3: Test It!
```swift
// The chat is now fully functional:
// 1. Tap "Messages" tab
// 2. Select a conversation (or create one)
// 3. Send/receive messages in real-time
```

---

## 📋 API Endpoints Reference

### REST Endpoints
```
GET  /api/v1/chat/conversations          # List all conversations
GET  /api/v1/chat/messages/:otherUserId  # Get message history (paginated)
POST /api/v1/chat/messages               # Send a message
PUT  /api/v1/chat/messages/:id/read      # Mark message as read
PUT  /api/v1/chat/conversations/:id/read # Mark conversation as read
```

### WebSocket Endpoint
```
ws://localhost:8080/ws/chat  (development)
wss://api.anonymouswall.com/ws/chat  (production)

Authentication: Sec-WebSocket-Protocol: access_token, <jwt-token>
```

### Message Types (WebSocket)
```swift
// Client → Server
.message        // Send a message
.typing         // Typing indicator
.markRead       // Mark as read

// Server → Client
.connected      // Connection confirmed
.message        // New message received
.typing         // Other user typing
.readReceipt    // Message read
.unreadCount    // Total unread count
.error          // Error message
```

---

## 🏗️ Architecture Layers

```
View → ViewModel → Repository → Service/WebSocket → Network/MessageStore
```

### Layer Responsibilities

| Layer | Files | Purpose |
|-------|-------|---------|
| **Models** | `ChatModels.swift` | Data structures |
| **Data** | `MessageStore.swift` | Thread-safe storage (Actor) |
| **Network** | `ChatService.swift`, `ChatWebSocketManager.swift` | API & WebSocket |
| **Business** | `ChatRepository.swift` | Combines REST + WebSocket |
| **Presentation** | `ChatViewModel.swift`, `ConversationsViewModel.swift` | UI logic |
| **View** | `ChatView.swift`, `ConversationsListView.swift` | SwiftUI UI |

---

## 🔑 Key Classes & Their Roles

### MessageStore (Actor)
**Purpose**: Thread-safe message storage  
**Usage**:
```swift
let store = MessageStore()
await store.addMessage(message, for: "user123")
let messages = await store.getMessages(for: "user123")
```

### ChatWebSocketManager (@MainActor)
**Purpose**: Real-time WebSocket connection  
**Usage**:
```swift
let manager = ChatWebSocketManager()
manager.connect(token: token, userId: userId)
manager.sendMessage(receiverId: "user123", content: "Hello")
```

### ChatRepository (@MainActor)
**Purpose**: Hybrid coordinator (REST + WebSocket)  
**Usage**:
```swift
let repo = ChatRepository(chatService: service, webSocketManager: manager, messageStore: store)
await repo.loadMessages(otherUserId: "user123", token: token, userId: userId)
await repo.sendMessage(receiverId: "user123", content: "Hello", token: token, userId: userId)
```

### ChatViewModel (@MainActor)
**Purpose**: Chat screen business logic  
**Usage**:
```swift
let viewModel = ChatViewModel(otherUserId: "user123", otherUserName: "John", repository: repo, messageStore: store)
viewModel.loadMessages(authState: authState)
viewModel.sendMessage(authState: authState)
```

### ChatView
**Purpose**: Chat screen UI  
**Usage**:
```swift
ChatView(viewModel: viewModel)
    .environmentObject(authState)
```

---

## 🧪 Testing Quick Reference

### Running Tests
```bash
# Run all chat tests
swift test --filter ChatViewModelTests
swift test --filter MessageStoreTests

# Run specific test
swift test --filter testAddMessageReturnsTrue
```

### Using Mocks in Tests
```swift
let mockService = MockChatService()
mockService.mockMessages = [/* test messages */]
mockService.getMessageHistoryBehavior = .success

let mockWebSocket = MockWebSocketManager()
mockWebSocket.shouldAutoConnect = true
mockWebSocket.simulateReceiveMessage(message)
```

---

## 🐛 Common Issues & Solutions

### Issue: WebSocket won't connect
**Solution**: Check that:
- JWT token is valid
- Backend WebSocket endpoint is running
- URL scheme is correct (ws:// for dev, wss:// for prod)

### Issue: Messages not appearing
**Solution**: Verify:
- `AuthState` has valid token and user
- REST API is reachable
- Messages are being added to MessageStore

### Issue: Retain cycle / memory leak
**Solution**: Ensure:
- All closures use `[weak self]`
- Tasks are cancelled in `deinit`
- Combine subscriptions stored in `cancellables`

### Issue: UI not updating
**Solution**: Check:
- ViewModel is `@MainActor`
- Properties are `@Published`
- View uses `@ObservedObject` or `@StateObject`

---

## 🔐 Security Checklist

- ✅ Tokens stored in Keychain (not UserDefaults)
- ✅ HTTPS/WSS in production
- ✅ No sensitive data in logs
- ✅ JWT passed with every request
- ✅ Input validation (message length)
- ✅ Authentication checks before operations

---

## 📊 Performance Tips

### Memory
- Use pagination (50 messages/page default)
- Clear old conversations periodically
- Cancel tasks when view disappears

### Network
- Prefer WebSocket for real-time (lower overhead)
- Fallback to REST when disconnected
- Use compression for large message batches

### UI
- Lazy loading with LazyVStack
- Avoid expensive computations in body
- Use diffable data sources for updates

---

## 🔍 Debugging Tips

### Enable Logging
```swift
// Logger is already configured
// Development: All logs enabled
// Production: Logs disabled

// View logs in Xcode console or Console.app
// Filtered by category: [Chat]
```

### Monitor WebSocket
```swift
// Check connection state
print(viewModel.connectionState)

// In ChatWebSocketManager, all events are logged:
// - Connection established
// - Messages sent/received
// - Reconnection attempts
// - Errors
```

### Inspect Message Store
```swift
// In tests or debugging
let count = await messageStore.getMessageCount(for: "user123")
let messages = await messageStore.getMessages(for: "user123")
print("Messages: \(messages.map { $0.id })")
```

---

## 📝 Code Snippets

### Send a Message Programmatically
```swift
// In a view or view model
viewModel.messageText = "Hello, World!"
viewModel.sendMessage(authState: authState)
```

### Mark Conversation as Read
```swift
viewModel.markConversationAsRead(authState: authState)
```

### Check Connection Status
```swift
switch viewModel.connectionState {
case .connected:
    print("WebSocket connected")
case .connecting:
    print("Connecting...")
case .reconnecting:
    print("Reconnecting...")
case .disconnected:
    print("Disconnected")
case .failed(let error):
    print("Failed: \(error)")
}
```

### Observe New Messages
```swift
// In ChatViewModel, already set up via Combine
repository.messagePublisher
    .sink { (message, conversationUserId) in
        // Message received
        print("New message: \(message.content)")
    }
    .store(in: &cancellables)
```

---

## 🎯 Best Practices

### ViewModels
- Always annotate with `@MainActor`
- Use `@Published` for observable properties
- Inject dependencies via constructor
- Cancel tasks in `deinit`

### Services
- Implement protocol for testability
- Use `async/await` (no completion handlers)
- Handle errors with typed enums
- Return domain models (not raw JSON)

### Repository
- Combine multiple data sources
- Provide single source of truth
- Handle fallback strategies
- Manage connection lifecycle

### Views
- Keep views declarative (no logic)
- Use `@ObservedObject` for ViewModels
- Provide accessibility labels
- Show loading/error states

---

## 📚 Additional Resources

- **CHAT_IMPLEMENTATION.md** - Detailed architecture guide
- **CHAT_ARCHITECTURE_VISUAL.md** - Flow diagrams and visuals
- **API_DOCUMENTATION.md** - Complete API reference
- **MessageStoreTests.swift** - 20 unit test examples
- **ChatViewModelTests.swift** - 17 integration test examples

---

## ✅ Pre-Merge Checklist

Before merging to main:

- [ ] All tests pass
- [ ] No compilation warnings
- [ ] WebSocket connects successfully
- [ ] Messages send and receive correctly
- [ ] UI updates in real-time
- [ ] Connection indicator works
- [ ] Typing indicator shows/hides
- [ ] Error states handled gracefully
- [ ] Memory leaks checked (Instruments)
- [ ] Accessibility labels verified
- [ ] Documentation updated
- [ ] Code reviewed by team

---

**Need Help?** Check the comprehensive docs or review the test files for examples.

**Found a Bug?** Check the debugging tips above or create an issue with:
1. Steps to reproduce
2. Expected behavior
3. Actual behavior
4. Relevant logs

**Want to Contribute?** See the "Future Enhancements" section in CHAT_IMPLEMENTATION.md
