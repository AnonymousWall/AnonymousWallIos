//
//  ConversationsListView.swift
//  AnonymousWallIos
//
//  List view for chat conversations
//

import SwiftUI

struct ConversationsListView: View {
    @EnvironmentObject var authState: AuthState
    @ObservedObject var viewModel: ConversationsViewModel
    var onSelectConversation: ((String, String) -> Void)?

    var body: some View {
        Group {
            if viewModel.isLoadingConversations {
                ProgressView()
            } else if viewModel.conversations.isEmpty {
                emptyStateView
            } else {
                conversationsList
            }
        }
        .navigationTitle("Messages")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.unreadCount > 0 {
                    BadgeView(count: viewModel.unreadCount)
                }
            }
        }
        .onAppear {
            viewModel.loadConversations(authState: authState)
        }
        .refreshable {
            await viewModel.refreshConversations(authState: authState)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") { viewModel.retry(authState: authState) }
            Button("Cancel", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - Subviews

    private var conversationsList: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                Button {
                    onSelectConversation?(conversation.userId, conversation.profileName)
                } label: {
                    ConversationRowView(conversation: conversation)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.textSecondary)
            Text("No conversations yet")
                .font(.headline)
                .foregroundColor(.textSecondary)
            Text("Your messages will appear here")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
