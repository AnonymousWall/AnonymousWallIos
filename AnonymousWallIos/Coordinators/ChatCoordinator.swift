//
//  ChatCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for chat navigation
//

import SwiftUI

/// Coordinator for managing chat navigation
class ChatCoordinator: Coordinator {
    enum Destination: Hashable {
        case chatDetail(otherUserId: String, otherUserName: String)
    }
    
    @Published var path = NavigationPath()
    @Published var selectedConversation: (userId: String, userName: String)?
    
    // Chat infrastructure - lazy initialized to avoid @MainActor requirements at init time
    private(set) lazy var messageStore: MessageStore = {
        MessageStore()
    }()
    
    private(set) lazy var webSocketManager: ChatWebSocketManager = {
        ChatWebSocketManager()
    }()
    
    private(set) lazy var chatRepository: ChatRepository = {
        ChatRepository(
            chatService: ChatService.shared,
            webSocketManager: self.webSocketManager,
            messageStore: self.messageStore
        )
    }()
    
    init() {
        // Lazy properties handle initialization when first accessed
    }
    
    func navigate(to destination: Destination) {
        switch destination {
        case .chatDetail(let userId, let userName):
            selectedConversation = (userId, userName)
            path.append(destination)
        }
    }
}
