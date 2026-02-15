# Chat Architecture Visual Guide

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │  ConversationsListView│    │       ChatView               │  │
│  │  ==================== │    │  ======================      │  │
│  │  - Conversation list  │────▶│  - Message list             │  │
│  │  - Unread badges      │    │  - Input field              │  │
│  │  - Last message       │    │  - Connection status        │  │
│  │  - Pull-to-refresh    │    │  - Typing indicator         │  │
│  └──────────────────────┘    └──────────────────────────────┘  │
│           │                              │                       │
│           │ @ObservedObject              │ @ObservedObject      │
│           ▼                              ▼                       │
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │ ConversationsViewModel│    │      ChatViewModel           │  │
│  │  @MainActor           │    │      @MainActor              │  │
│  └──────────────────────┘    └──────────────────────────────┘  │
│           │                              │                       │
└───────────┼──────────────────────────────┼───────────────────────┘
            │                              │
            │                              │
┌───────────┼──────────────────────────────┼───────────────────────┐
│           │        BUSINESS LOGIC        │                       │
├───────────┼──────────────────────────────┼───────────────────────┤
│           │                              │                       │
│           └──────────┬───────────────────┘                       │
│                      │                                           │
│                      ▼                                           │
│           ┌──────────────────────┐                              │
│           │   ChatRepository     │   Hybrid Coordinator         │
│           │   @MainActor         │                              │
│           └──────────┬───────────┘                              │
│                      │                                           │
│         ┌────────────┴────────────┐                             │
│         │                         │                             │
│         ▼                         ▼                             │
│  ┌─────────────┐         ┌──────────────────┐                  │
│  │ ChatService │         │ChatWebSocketMgr  │                  │
│  │ (REST API)  │         │  (WebSocket)     │                  │
│  └─────────────┘         └──────────────────┘                  │
│         │                         │                             │
└─────────┼─────────────────────────┼─────────────────────────────┘
          │                         │
          │                         │
┌─────────┼─────────────────────────┼─────────────────────────────┐
│         │      DATA LAYER         │                             │
├─────────┼─────────────────────────┼─────────────────────────────┤
│         │                         │                             │
│         ▼                         ▼                             │
│  ┌──────────────────────────────────────────┐                  │
│  │         MessageStore (Actor)              │                  │
│  │  Thread-Safe Message Management           │                  │
│  │  - Deduplication                          │                  │
│  │  - Sorting                                │                  │
│  │  - Temporary messages                     │                  │
│  │  - Read status                            │                  │
│  └──────────────────────────────────────────┘                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
          │                         │
          ▼                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      NETWORK LAYER                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  REST API:                    WebSocket:                         │
│  GET  /chat/conversations     ws://host/ws/chat                  │
│  GET  /chat/messages/:id      - Real-time messages              │
│  POST /chat/messages          - Typing indicators               │
│  PUT  /chat/messages/:id/read - Read receipts                   │
│                               - Connection management            │
└───────────────────────────────────────────────────────────────────┘
```

## Message Flow Diagrams

### 1. Initial Load Flow

```
User Opens Chat
     │
     ▼
ChatViewModel.loadMessages()
     │
     ├─────▶ ChatRepository.loadMessages()
     │            │
     │            ├─────▶ ChatService (REST API)
     │            │           │
     │            │           └─────▶ GET /chat/messages/:otherUserId
     │            │                      │
     │            │                      ▼
     │            ├─────▶ MessageStore.addMessages()
     │            │           │
     │            │           └─────▶ Deduplicate + Sort
     │            │
     │            └─────▶ ChatWebSocketManager.connect()
     │                        │
     │                        └─────▶ ws://host/ws/chat
     │
     └─────▶ Update UI with messages
```

### 2. Send Message Flow (Optimistic UI)

```
User Sends Message
     │
     ▼
ChatViewModel.sendMessage()
     │
     ├─────▶ Clear input field (immediate)
     │
     └─────▶ ChatRepository.sendMessage()
              │
              ├─────▶ Create TemporaryMessage
              │           │
              │           └─────▶ MessageStore.addTemporaryMessage()
              │                      │
              │                      └─────▶ Display in UI immediately
              │
              ├─────▶ WebSocket connected?
              │       │
              │       ├─YES─▶ ChatWebSocketManager.sendMessage()
              │       │           │
              │       │           └─────▶ Send via WebSocket
              │       │                      │
              │       │                      └─────▶ Server confirms
              │       │                                 │
              │       │                                 └─────▶ Replace temp message
              │       │
              │       └─NO──▶ ChatService.sendMessage() (REST fallback)
              │                   │
              │                   └─────▶ POST /chat/messages
              │                              │
              │                              └─────▶ Replace temp message
              │
              └─────▶ Update message status
                      (sending → sent → delivered)
```

### 3. Receive Message Flow (Real-time)

```
Server Sends Message
     │
     ▼
WebSocket receives data
     │
     ▼
ChatWebSocketManager.handleReceivedMessage()
     │
     ├─────▶ Parse JSON
     │
     ├─────▶ messageSubject.send(message)
     │           │
     │           └─────▶ ChatRepository observes
     │                      │
     │                      └─────▶ MessageStore.addMessage()
     │                                 │
     │                                 ├─────▶ Check for duplicate
     │                                 │       (Skip if exists)
     │                                 │
     │                                 └─────▶ Add to conversation
     │
     └─────▶ ChatViewModel observes
                 │
                 └─────▶ Update @Published messages
                            │
                            └─────▶ SwiftUI re-renders
```

### 4. WebSocket Reconnection Flow

```
Connection Lost
     │
     ▼
ChatWebSocketManager detects failure
     │
     ├─────▶ connectionStateSubject.send(.failed)
     │           │
     │           └─────▶ UI shows "Connection failed"
     │
     ├─────▶ Attempt < maxAttempts?
     │       │
     │       ├─YES─▶ Calculate exponential backoff
     │       │       delay = min(2^attempts, 30)
     │       │           │
     │       │           └─────▶ Wait delay seconds
     │       │                      │
     │       │                      └─────▶ Reconnect
     │       │                                 │
     │       │                                 ├─SUCCESS─▶ .connected
     │       │                                 │              │
     │       │                                 │              └─────▶ Recover messages
     │       │                                 │                      (fetch newer than last)
     │       │                                 │
     │       │                                 └─FAIL────▶ Retry again
     │       │
     │       └─NO──▶ Give up
     │               └─────▶ User can manually retry
     │
     └─────▶ Meanwhile: Fall back to REST API
             (User can still send/receive via polling)
```

### 5. Thread Safety Model

```
┌─────────────────────────────────────────────────────────────┐
│                     MAIN THREAD                              │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  @MainActor                                                  │
│  ┌─────────────────┐                                        │
│  │  ViewModels     │                                        │
│  │  - ChatViewModel│                                        │
│  │  - ConversationsVM                                       │
│  └────────┬────────┘                                        │
│           │                                                  │
│           │ async/await                                     │
│           │                                                  │
│  ┌────────▼────────┐                                        │
│  │  Repository     │                                        │
│  └────────┬────────┘                                        │
│           │                                                  │
└───────────┼─────────────────────────────────────────────────┘
            │
            │ await (crosses isolation boundary)
            │
┌───────────▼─────────────────────────────────────────────────┐
│                   ACTOR ISOLATION                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  actor MessageStore                                          │
│  ┌──────────────────────────────────────┐                   │
│  │ Serialized message operations         │                  │
│  │ - addMessage()                        │                  │
│  │ - getMessages()                       │                  │
│  │ - updateReadStatus()                  │                  │
│  │ All operations are thread-safe        │                  │
│  └──────────────────────────────────────┘                   │
│                                                               │
└──────────────────────────────────────────────────────────────┘
            │
            │ async operations
            │
┌───────────▼─────────────────────────────────────────────────┐
│                BACKGROUND THREADS                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐      ┌────────────────────┐          │
│  │ URLSession       │      │ WebSocket Task     │          │
│  │ (Network)        │      │ (Real-time)        │          │
│  └──────────────────┘      └────────────────────┘          │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## State Management

### Message States

```
┌──────────────────────────────────────────────────────────────┐
│                    Message Lifecycle                          │
└──────────────────────────────────────────────────────────────┘

User Types Message
        ↓
    [SENDING] ───────────────┐
        │                     │
        │ Success             │ Failure
        ↓                     ↓
     [SENT] ────────────► [FAILED]
        │                     │
        │ Delivered           │ Retry
        ↓                     │
   [DELIVERED] ◄──────────────┘
        │
        │ Read by recipient
        ↓
     [READ]

Status Icons:
- SENDING:   clock icon
- SENT:      single checkmark
- DELIVERED: single checkmark
- READ:      double checkmark (blue)
- FAILED:    exclamation mark (red)
```

### Connection States

```
┌──────────────────────────────────────────────────────────────┐
│                Connection State Machine                       │
└──────────────────────────────────────────────────────────────┘

[DISCONNECTED]
     │
     │ connect()
     ▼
[CONNECTING] ─────────┐
     │                │
     │ Success        │ Failure
     ▼                ▼
[CONNECTED]      [FAILED] ──────────┐
     │                │              │
     │ Connection     │ Retry        │
     │ Lost           ▼              │ Max attempts
     ▼          [RECONNECTING] ◄─────┤
[RECONNECTING]       │              │
     │               │ Success       │ Give up
     │ Success       ▼               ▼
     └──────────► [CONNECTED]  [DISCONNECTED]

UI Indicators:
- CONNECTING:    Orange bar "Connecting..."
- RECONNECTING:  Orange bar "Reconnecting..."
- FAILED:        Red bar "Connection failed"
- CONNECTED:     No indicator (normal)
- DISCONNECTED:  No WebSocket (REST fallback)
```

## Data Flow Patterns

### Read Path (Message Retrieval)

```
┌──────────┐      ┌────────────┐      ┌──────────────┐
│   View   │─────▶│ ViewModel  │─────▶│ Repository   │
└──────────┘      └────────────┘      └──────────────┘
                                              │
                                              ├─────▶ REST API (initial)
                                              │
                                              ├─────▶ WebSocket (real-time)
                                              │
                                              └─────▶ MessageStore (cache)
                                                         │
                                                         ▼
                                                   [Message Array]
                                                   (deduplicated,
                                                    sorted)
```

### Write Path (Message Sending)

```
┌──────────┐      ┌────────────┐      ┌──────────────┐
│   View   │─────▶│ ViewModel  │─────▶│ Repository   │
└──────────┘      └────────────┘      └──────────────┘
                                              │
                                              ├─────▶ MessageStore
                                              │       (add temp message)
                                              │
                                              ├─────▶ WebSocket (if connected)
                                              │       OR
                                              │       REST API (fallback)
                                              │
                                              └─────▶ MessageStore
                                                      (confirm message)
```

## Testing Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                      Test Pyramid                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│                      /\                                       │
│                     /  \    Integration Tests                │
│                    /    \   (ChatViewModelTests)             │
│                   /      \  17 tests                         │
│                  /────────\                                   │
│                 /          \                                  │
│                /   Unit     \                                 │
│               /    Tests     \                                │
│              /                \                               │
│             /  MessageStore    \  20 tests                   │
│            /     Tests          \                             │
│           /──────────────────────\                            │
│          /                        \                           │
│         /      Mock Services       \                          │
│        /  (MockChatService,         \                         │
│       /    MockWebSocketManager)     \                        │
│      /_______________________________ \                       │
│                                                               │
└──────────────────────────────────────────────────────────────┘

Test Coverage:
✅ Message deduplication
✅ Message ordering
✅ Temporary messages
✅ Read status updates
✅ Connection states
✅ Typing indicators
✅ Optimistic sending
✅ Error handling
✅ Retry logic
✅ Authentication
```

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading**: Load messages on demand (pagination)
2. **Deduplication**: Prevent duplicate messages in store (O(n) → O(1) with Set)
3. **Sorted Insertion**: Maintain chronological order without full sorts
4. **WebSocket Efficiency**: Reduces HTTP overhead (no repeated connections)
5. **Optimistic UI**: Immediate feedback before network confirmation
6. **Actor Isolation**: Lock-free concurrency with message passing

### Memory Management

```
Potential Memory Issues          Mitigation
─────────────────────────────────────────────────────────
Retain cycles in closures   →   [weak self] in closures
Uncancelled tasks          →    Task cancellation in deinit
WebSocket connections      →    Disconnect on view disappear
Combine subscriptions      →    Store in cancellables set
Message accumulation       →    Pagination + cleanup old messages
```

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Authentication                                           │
│     ├─ JWT Token (Bearer authentication)                    │
│     ├─ Keychain storage (secure)                            │
│     └─ Token passed to all requests                         │
│                                                               │
│  2. Transport Security                                       │
│     ├─ HTTPS for REST API (production)                      │
│     ├─ WSS for WebSocket (production)                       │
│     └─ HTTP/WS for development only                         │
│                                                               │
│  3. Data Privacy                                             │
│     ├─ No message content in logs (production)              │
│     ├─ Structured logging with levels                       │
│     └─ Environment-based log filtering                      │
│                                                               │
│  4. Input Validation                                         │
│     ├─ Message content: 1-5000 characters                   │
│     ├─ Empty message prevention                             │
│     └─ Authentication checks before operations              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     iOS Application                           │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  Development:  localhost:8080                                 │
│  Production:   api.anonymouswall.com                          │
│                                                                │
└───────────────┬──────────────────────────────────────────────┘
                │
                │ HTTPS / WSS
                │
┌───────────────▼──────────────────────────────────────────────┐
│                     Backend Server                            │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  REST API Endpoints:                                          │
│  ├─ GET  /api/v1/chat/conversations                          │
│  ├─ GET  /api/v1/chat/messages/:otherUserId                  │
│  ├─ POST /api/v1/chat/messages                               │
│  └─ PUT  /api/v1/chat/messages/:messageId/read               │
│                                                                │
│  WebSocket Endpoint:                                          │
│  └─ ws://host/ws/chat                                         │
│     (with JWT authentication)                                 │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

---

## Quick Reference

### Key Classes
- `Message`: Core message model
- `MessageStore`: Thread-safe actor for message management
- `ChatWebSocketManager`: WebSocket connection handler
- `ChatService`: REST API client
- `ChatRepository`: Hybrid coordinator (REST + WebSocket)
- `ChatViewModel`: Chat screen ViewModel
- `ConversationsViewModel`: Conversations list ViewModel

### Key Files
- Models: `ChatModels.swift`
- Services: `MessageStore.swift`, `ChatWebSocketManager.swift`, `ChatRepository.swift`, `ChatService.swift`
- ViewModels: `ChatViewModel.swift`, `ConversationsViewModel.swift`
- Views: `ChatView.swift`, `ConversationsListView.swift`
- Tests: `MessageStoreTests.swift`, `ChatViewModelTests.swift`

### Integration Steps
1. Create shared instances (MessageStore, WebSocketManager, Repository)
2. Initialize ViewModels with dependencies
3. Pass AuthState via `.environmentObject()`
4. Add navigation links to chat views
5. Test connection and message flow

---

**Implementation Status**: ✅ Complete and Production Ready
