//
//  MessagesView.swift
//  AnonymousWallIos
//
//  Messages view with coordinator integration
//

import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @ObservedObject var coordinator: ChatCoordinator
    @StateObject private var conversationsViewModel: ConversationsViewModel
    
    init(coordinator: ChatCoordinator) {
        self.coordinator = coordinator
        _conversationsViewModel = StateObject(wrappedValue: ConversationsViewModel(repository: coordinator.chatRepository))
    }
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ConversationsListView(
                viewModel: conversationsViewModel,
                onSelectConversation: { userId, userName in
                    coordinator.navigate(to: .chatDetail(otherUserId: userId, otherUserName: userName))
                }
            )
            .navigationDestination(for: ChatCoordinator.Destination.self) { destination in
                switch destination {
                case .chatDetail(let userId, let userName):
                    let chatViewModel = ChatViewModel(
                        otherUserId: userId,
                        otherUserName: userName,
                        repository: coordinator.chatRepository,
                        messageStore: coordinator.messageStore
                    )
                    ChatView(viewModel: chatViewModel)
                }
            }
        }
        .onDisappear {
            // ✅ Only disconnect when leaving the messages tab entirely
            // NOT when navigating between ConversationsListView and ChatView
            conversationsViewModel.disconnect()
        }
        .onReceive(blockViewModel.userBlockedPublisher) { blockedUserId in
            conversationsViewModel.removeConversationsFromUser(blockedUserId)
        }
    }
}

#Preview {
    MessagesView(coordinator: ChatCoordinator())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}
