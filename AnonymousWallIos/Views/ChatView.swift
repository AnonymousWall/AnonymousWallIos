//
//  ChatView.swift
//  AnonymousWallIos
//
//  Chat conversation view with real-time messaging and image support
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ChatView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ChatViewModel
    
    @FocusState private var isInputFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageURL: String? = nil
    @State private var selectedImageItem: ImageViewerItem? = nil
    
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
            
            // Image upload progress
            if viewModel.isUploadingImage {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.7)
                    Text("Uploading image...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
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
                                    isCurrentUser: message.senderId == authState.currentUser?.id,
                                    onTapImage: { url in
                                        selectedImageURL = url
                                        selectedImageItem = ImageViewerItem(index: 0)
                                    }
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
                .onChange(of: viewModel.messages.count) { _, _ in
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
                let isUploading = viewModel.isUploadingImage
                // Image picker button
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundColor(isUploading ? .gray : .accentColor)
                }
                .disabled(viewModel.isUploadingImage)
                .onChange(of: selectedPhotoItem) { _, item in
                    guard let item else { return }
                    Task {
                        do {
                            if let data = try await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                viewModel.sendImage(image, authState: authState)
                            }
                        } catch {
                            viewModel.errorMessage = "Failed to load image: \(error.localizedDescription)"
                        }
                        selectedPhotoItem = nil
                    }
                }
                .accessibilityLabel("Send image")
                
                // Text input
                TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .onChange(of: viewModel.messageText) { _, _ in
                        viewModel.onTextChanged()
                    }
                    .accessibilityLabel("Message input")
                
                // Send button
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
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                viewModel.markConversationAsRead(authState: authState)
            }
        }
        .onDisappear {
            viewModel.disconnect()
        }
        .fullScreenCover(item: $selectedImageItem) { _ in
            FullScreenImageViewer(imageURLs: [selectedImageURL ?? ""], initialIndex: 0)
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
    var onTapImage: ((String) -> Void)?
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Image bubble
                if let imageUrl = message.imageUrl {
                    KFImage(URL(string: imageUrl))
                        .placeholder {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 200, height: 200)
                                .overlay(ProgressView())
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(12)
                        .onTapGesture { onTapImage?(imageUrl) }
                        .accessibilityLabel("Image message")
                        .accessibilityHint("Double tap to view full screen")
                }
                
                // Text bubble (only if non-empty)
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .padding(12)
                        .background(isCurrentUser ? Color.accentColor : Color(.systemGray6))
                        .cornerRadius(16)
                        .accessibilityLabel("Message: \(message.content)")
                }
                
                // Timestamp + status
                HStack(spacing: 4) {
                    Text(DateFormatting.formatRelativeTime(message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if isCurrentUser {
                        statusIcon
                    }
                }
            }
            .frame(maxWidth: 280, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser { Spacer() }
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
