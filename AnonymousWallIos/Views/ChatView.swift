//
//  ChatView.swift
//  AnonymousWallIos
//
//  Chat conversation view with real-time messaging
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ChatViewModel
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Connection status bar
            if case .connecting = viewModel.connectionState {
                connectionStatusBar(text: "Connecting...", color: .orange)
            } else if case .reconnecting = viewModel.connectionState {
                connectionStatusBar(text: "Reconnecting...", color: .orange)
            } else if case .failed = viewModel.connectionState {
                connectionStatusBar(text: "Connection failed", color: .red)
            }
            
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoadingMessages {
                            ProgressView()
                                .padding()
                        } else if viewModel.messages.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isCurrentUser: message.senderId == authState.currentUser?.id
                                )
                                .id(message.id)
                            }
                        }
                        
                        // Typing indicator
                        if viewModel.isTyping {
                            typingIndicatorView
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    // Auto-scroll to bottom when new message arrives
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input bar
            HStack(spacing: 12) {
                TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .onChange(of: viewModel.messageText) { _ in
                        viewModel.onTextChanged()
                    }
                    .accessibilityLabel("Message input")
                
                Button(action: {
                    HapticFeedback.medium()
                    viewModel.sendMessage(authState: authState)
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                }
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingMessage)
                .accessibilityLabel("Send message")
            }
            .padding()
        }
        .navigationTitle(viewModel.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMessages(authState: authState)
            viewModel.viewDidAppear()
            // Mark conversation as read when view appears
            Task {
                // Small delay to ensure messages are loaded first
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                viewModel.markConversationAsRead(authState: authState)
            }
        }
        .onDisappear {
            viewModel.disconnect()
            // Note: disconnect() no longer calls repository.disconnect()
            // It only sets isViewActive = false
            // WebSocket lifecycle is managed at MessagesView (tab) level
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") {
                viewModel.retry(authState: authState)
            }
            Button("Cancel", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start a conversation by sending a message")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var typingIndicatorView: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever(), value: viewModel.isTyping)
                
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(0.2), value: viewModel.isTyping)
                
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever().delay(0.4), value: viewModel.isTyping)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Spacer()
        }
    }
    
    private func connectionStatusBar(text: String, color: Color) -> some View {
        HStack {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.7)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(color)
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .padding(12)
                    .background(isCurrentUser ? Color.accentColor : Color(.systemGray6))
                    .cornerRadius(16)
                    .accessibilityLabel("Message: \(message.content)")
                
                HStack(spacing: 4) {
                    Text(DateFormatting.formatRelativeTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if isCurrentUser {
                        // Status indicator
                        statusIcon
                    }
                }
            }
            .frame(maxWidth: 280, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch message.localStatus {
            case .sending:
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            case .sent, .delivered:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
}
