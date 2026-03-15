//
//  ChatView.swift
//  AnonymousWallIos
//
//  Chat conversation view with real-time messaging and image support
//

import SwiftUI
import PhotosUI

struct ChatView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ChatViewModel

    @FocusState private var isInputFocused: Bool
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var pendingImage: UIImage? = nil
    @State private var showImageConfirmation = false
    @State private var selectedImageURL: String? = nil
    @State private var selectedImageItem: ImageViewerItem? = nil
    @State private var showBlockConfirmation = false
    @State private var showBlockSuccessAlert = false

    /// Captures the top message ID before a load-more so scroll position
    /// can be restored after older messages are prepended.
    @State private var firstVisibleMessageId: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            connectionBanner
            uploadProgressBanner
            messageList
            Divider()
            inputBar
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(viewModel.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { chatOptionsMenu }
        .confirmationDialog(
            "Block \(viewModel.otherUserName)?",
            isPresented: $showBlockConfirmation,
            titleVisibility: .visible
        ) {
            Button("Block \(viewModel.otherUserName)", role: .destructive) {
                blockViewModel.blockUser(targetUserId: viewModel.otherUserId, authState: authState) {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They will no longer be able to see your content, and you won't see theirs.")
        }
        .onAppear {
            ActiveConversationTracker.shared.activeConversationId = viewModel.otherUserId
            viewModel.loadMessages(authState: authState)
            viewModel.viewDidAppear()
        }
        .onDisappear {
            ActiveConversationTracker.shared.activeConversationId = nil
            viewModel.disconnect()
        }
        .fullScreenCover(item: $selectedImageItem) { _ in
            FullScreenImageViewer(imageURLs: [selectedImageURL ?? ""], initialIndex: 0)
        }
        .sheet(isPresented: $showImageConfirmation, onDismiss: { pendingImage = nil }) {
            if let image = pendingImage {
                ImageSendConfirmationSheet(image: image) {
                    viewModel.sendImage(image, authState: authState)
                }
                .presentationDetents([.medium])
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") { viewModel.retry(authState: authState) }
            Button("Cancel", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage { Text(error) }
        }
        .alert("User Blocked", isPresented: $showBlockSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(viewModel.otherUserName) has been blocked.")
        }
        .alert("Block Error", isPresented: .init(
            get: { blockViewModel.errorMessage != nil },
            set: { if !$0 { blockViewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { blockViewModel.errorMessage = nil }
        } message: {
            if let error = blockViewModel.errorMessage { Text(error) }
        }
    }

    // MARK: - Banners

    @ViewBuilder
    private var connectionBanner: some View {
        switch viewModel.connectionState {
        case .connecting:
            ConnectionStatusBarView(text: "Connecting...", color: .orange)
        case .reconnecting:
            ConnectionStatusBarView(text: "Reconnecting...", color: .orange)
        case .failed:
            ConnectionStatusBarView(text: "Connection failed", color: .accentRed, showSpinner: false)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var uploadProgressBanner: some View {
        if viewModel.isUploadingImage {
            HStack(spacing: 8) {
                ProgressView().tint(.white).scaleEffect(0.7)
                Text("Uploading image...")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    loadMoreTrigger
                    messageContent
                    if viewModel.isTyping {
                        TypingIndicatorView(isTyping: viewModel.isTyping)
                    }
                }
                .padding()
            }
            // Scroll to bottom when new messages arrive at the bottom
            .onChange(of: viewModel.messages.count) { oldCount, newCount in
                guard newCount > oldCount else { return }
                if let savedId = firstVisibleMessageId {
                    // Older messages prepended — restore position without jumping
                    proxy.scrollTo(savedId, anchor: .top)
                    firstVisibleMessageId = nil
                } else if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            // Jump to bottom after initial load completes
            .onChange(of: viewModel.isLoadingMessages) { _, isLoading in
                if !isLoading, let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private var loadMoreTrigger: some View {
        if viewModel.isLoadingMore {
            ProgressView()
                .padding(.vertical, 8)
        } else if viewModel.hasMoreMessages && !viewModel.isLoadingMessages {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    firstVisibleMessageId = viewModel.messages.first?.id
                    viewModel.loadMoreMessages(authState: authState)
                }
        }
    }

    @ViewBuilder
    private var messageContent: some View {
        if viewModel.isLoadingMessages {
            ProgressView().padding()
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
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Image(systemName: "photo")
                    .font(.system(size: 22))
                    .foregroundColor(viewModel.isUploadingImage ? .gray : .accentColor)
            }
            .disabled(viewModel.isUploadingImage)
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    do {
                        if let data = try await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            pendingImage = image
                            showImageConfirmation = true
                        }
                    } catch {
                        viewModel.errorMessage = "Failed to load image: \(error.localizedDescription)"
                    }
                    selectedPhotoItem = nil
                }
            }
            .accessibilityLabel("Send image")

            TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color.surfaceSecondary)
                .cornerRadius(20)
                .focused($isInputFocused)
                .onChange(of: viewModel.messageText) { _, _ in
                    viewModel.onTextChanged()
                }
                .accessibilityLabel("Message input")

            Button {
                HapticFeedback.medium()
                viewModel.sendMessage(authState: authState)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .gray : .accentColor
                    )
            }
            .disabled(
                viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isSendingMessage
            )
            .accessibilityLabel("Send message")
        }
        .padding()
        .background(Color.surfacePrimary)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var chatOptionsMenu: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(role: .destructive) {
                    HapticFeedback.warning()
                    showBlockConfirmation = true
                } label: {
                    Label("Block User", systemImage: "hand.raised.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
            }
            .accessibilityLabel("Chat options")
            .accessibilityHint("Double tap to access chat options including block user")
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.textSecondary)
            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.textSecondary)
            Text("Start a conversation by sending a message")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
