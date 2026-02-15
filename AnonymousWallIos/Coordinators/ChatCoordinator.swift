//
//  ChatCoordinator.swift
//  AnonymousWallIos
//
//  Coordinator for chat navigation
//

import SwiftUI

/// Coordinator for managing chat navigation
@MainActor
class ChatCoordinator: Coordinator {
    enum Destination: Hashable {
        case chatDetail(otherUserId: String, otherUserName: String)
    }
    
    @Published var path = NavigationPath()
    @Published var selectedConversation: (userId: String, userName: String)?
    
    // Chat infrastructure
    let messageStore: MessageStore
    let webSocketManager: ChatWebSocketManager
    let chatRepository: ChatRepository
    
    init() {
        // Initialize chat infrastructure
        self.messageStore = MessageStore()
        self.webSocketManager = ChatWebSocketManager()
        self.chatRepository = ChatRepository(
            chatService: ChatService.shared,
            webSocketManager: webSocketManager,
            messageStore: messageStore
        )
    }
    
    func navigate(to destination: Destination) {
        switch destination {
        case .chatDetail(let userId, let userName):
            selectedConversation = (userId, userName)
            path.append(destination)
        }
    }
}
