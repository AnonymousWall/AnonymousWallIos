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
                    Badge(count: viewModel.unreadCount)
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

// MARK: - Conversation Row View

struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.profileName.prefix(1))
                        .font(.title3.bold())
                        .foregroundColor(.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.profileName)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(DateFormatting.formatRelativeTime(lastMessage.createdAt))
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                HStack {
                    if let lastMessage = conversation.lastMessage {
                        // Show image preview text if image message
                        let preview: String = {
                            if lastMessage.imageUrl != nil && lastMessage.content.isEmpty {
                                return "📷 Photo"
                            }
                            return lastMessage.content
                        }()
                        
                        Text(preview)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    } else {
                        Text("No messages")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Badge(count: conversation.unreadCount)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Badge View

struct Badge: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, count > 9 ? 6 : 8)
            .padding(.vertical, 4)
            .background(Color.red)
            .cornerRadius(10)
    }
}
