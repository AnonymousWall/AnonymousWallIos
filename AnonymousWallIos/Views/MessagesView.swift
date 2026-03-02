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
                case .chatDetailById(let conversationId):
                    ChatDetailByConversationIdView(
                        conversationId: conversationId,
                        repository: coordinator.chatRepository,
                        messageStore: coordinator.messageStore
                    )
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
        .background(Color.appBackground.ignoresSafeArea())
    }
}

#Preview {
    MessagesView(coordinator: ChatCoordinator())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}

// MARK: - Chat Detail By Conversation ID View

private struct ChatDetailByConversationIdView: View {
    let conversationId: String
    let repository: ChatRepository
    let messageStore: MessageStore

    @EnvironmentObject var authState: AuthState
    @State private var chatViewModel: ChatViewModel?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let viewModel = chatViewModel {
                ChatView(viewModel: viewModel)
            } else if loadFailed {
                Text("This conversation could not be found.")
                    .foregroundColor(.textSecondary)
                    .padding()
            } else {
                ProgressView()
            }
        }
        .task { await loadConversation() }
    }

    private func loadConversation() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }
        do {
            let conversations = try await repository.loadConversations(
                token: token, userId: userId)
            if let match = conversations.first(where: { $0.id == conversationId }) {
                chatViewModel = ChatViewModel(
                    otherUserId: match.userId,
                    otherUserName: match.profileName,
                    repository: repository,
                    messageStore: messageStore
                )
            } else {
                loadFailed = true
            }
        } catch {
            loadFailed = true
        }
    }
}
