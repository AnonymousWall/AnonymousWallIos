//
//  HomeView.swift
//  AnonymousWallIos
//
//  Home view showing national posts
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var coordinator: HomeCoordinator
    @ObservedObject var notificationsViewModel: NotificationsViewModel
    @State private var showSortPicker = false
    @State private var showNotifications = false

    // Minimum height for scrollable content when list is empty
    private let minimumScrollableHeight: CGFloat = 300
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            VStack(spacing: 0) {
                // Password setup alert banner
                if authState.needsPasswordSetup {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.accentOrange)
                        Text("Please set up your password to secure your account")
                            .font(.caption)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button("Set Now") {
                            coordinator.navigate(to: .setPassword)
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentBlue)
                    }
                    .padding()
                    .background(Color.accentOrange.opacity(Opacity.light))
                    .cornerRadius(8)
                    .padding()
                }
                
                // Sort trigger badge
                HStack {
                    Button {
                        showSortPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.selectedSortOrder.icon)
                                .font(.caption.weight(.semibold))
                            Text(viewModel.selectedSortOrder.displayName)
                                .font(.labelMedium)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .foregroundColor(viewModel.selectedSortOrder.accentColor)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedSortOrder.accentColor.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(viewModel.selectedSortOrder.accentColor.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }
                    .accessibilityLabel("Sort posts")
                    .accessibilityValue(viewModel.selectedSortOrder.displayName)
                    .accessibilityHint("Double tap to change sort order")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Post list
                ScrollView {
                    if viewModel.isLoadingPosts && viewModel.posts.isEmpty {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in
                                PostRowView(post: .placeholder, isOwnPost: false, onLike: {}, onDelete: {}, isLoading: true)
                            }
                        }
                        .padding()
                    } else if viewModel.posts.isEmpty && !viewModel.isLoadingPosts {
                        VStack {
                            Spacer()
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.brandGradient)
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 30)
                                    
                                    Image(systemName: "globe.americas.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(LinearGradient.brandGradient)
                                        .accessibilityHidden(true)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("No national posts yet")
                                        .font(.title3.bold())
                                        .foregroundColor(.textPrimary)
                                    Text("Be the first to post!")
                                        .font(.body)
                                        .foregroundColor(.textSecondary)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("No national posts yet. Be the first to post!")
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.posts) { post in
                                Button {
                                    coordinator.navigate(to: .postDetail(post))
                                } label: {
                                    PostRowView(
                                        post: post,
                                        isOwnPost: post.author.id == authState.currentUser?.id,
                                        onLike: { viewModel.toggleLike(for: post, authState: authState) },
                                        onDelete: { viewModel.deletePost(post, authState: authState) },
                                        onTapAuthor: {
                                            coordinator.navigateToChatWithUser(userId: post.author.id, userName: post.author.profileName)
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("View post: \(post.title)")
                                .accessibilityHint("Double tap to view full post and comments")
                                .onAppear {
                                    // Load more when the last post appears
                                    viewModel.loadMoreIfNeeded(for: post, authState: authState)
                                }
                            }
                            
                            // Loading indicator at bottom
                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                    }
                }
                .refreshable {
                    await viewModel.refreshPosts(authState: authState)
                }
                .tint(.accentPurple)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.accentRed)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("National")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NotificationBellButton(notificationsViewModel: notificationsViewModel,
                                          showNotifications: $showNotifications)
                }
            }
            .navigationDestination(for: HomeCoordinator.Destination.self) { destination in
                switch destination {
                case .postDetail(let post):
                    if let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) {
                        PostDetailView(
                            post: Binding(
                                get: { viewModel.posts[index] },
                                set: { viewModel.posts[index] = $0 }
                            ),
                            onTapAuthor: { userId, userName in
                                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                            }
                        )
                    } else {
                        // Fallback if post is not found in the list
                        PostDetailView(
                            post: .constant(post),
                            onTapAuthor: { userId, userName in
                                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                            }
                        )
                    }
                case .postDetailById(let postId):
                    // Deep-link navigation: no pre-fetched post available.
                    // PostDetailByIdView holds a mutable @State placeholder so
                    // PostDetailView.refreshPost can update it on appear.
                    PostDetailByIdView(postId: postId) { userId, userName in
                        coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                    }
                case .setPassword:
                    EmptyView() // Handled as a sheet
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $coordinator.showSetPassword) {
            SetPasswordView(authService: AuthService.shared)
        }
        .sheet(isPresented: $showNotifications, onDismiss: {
            // Refresh badge as soon as sheet closes
            Task { await notificationsViewModel.fetchUnreadCount(authState: authState) }
            guard let pending = notificationsViewModel.pendingNavigation else { return }
            notificationsViewModel.pendingNavigation = nil
            switch pending.type {
            case .comment:
                coordinator.navigate(to: .postDetailById(pending.entityId))
            case .internshipComment:
                coordinator.tabCoordinator?.selectTab(3)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    coordinator.tabCoordinator?.internshipCoordinator
                        .navigate(to: .internshipDetailById(pending.entityId))
                }
            case .marketplaceComment:
                coordinator.tabCoordinator?.selectTab(4)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    coordinator.tabCoordinator?.marketplaceCoordinator
                        .navigate(to: .itemDetailById(pending.entityId))
                }
            case .unknown: break
            }
        }) {
            NotificationsView(viewModel: notificationsViewModel)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showSortPicker) {
            SortPickerSheet(selectedSort: $viewModel.selectedSortOrder)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .onChange(of: viewModel.selectedSortOrder) { _, _ in
            viewModel.sortOrderChanged(authState: authState)
        }
        .onAppear {
            // Show password setup if needed (only once)
            if authState.needsPasswordSetup && !authState.hasShownPasswordSetup {
                authState.markPasswordSetupShown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    coordinator.navigate(to: .setPassword)
                }
            }
            
            // Load posts
            viewModel.loadPosts(authState: authState)
            Task { await notificationsViewModel.fetchUnreadCount(authState: authState) }
        }
        .onDisappear {
            // Cancel any ongoing load task when view disappears
            viewModel.cleanup()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openNotificationInbox)) { _ in
            guard coordinator.tabCoordinator?.selectedTab == 0 else { return }
            showNotifications = true
        }
        .onReceive(blockViewModel.userBlockedPublisher) { blockedUserId in
            viewModel.removePostsFromUser(blockedUserId)
        }
    }
}

#Preview {
    HomeView(coordinator: HomeCoordinator(), notificationsViewModel: NotificationsViewModel())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}

// MARK: - PostDetailByIdView

/// Wrapper view used when navigating to a post by ID only (e.g. push notification deep link).
/// Holds a mutable @State placeholder so PostDetailView.refreshPost can populate the full data.
// MARK: - PostDetailByIdView

/// Wrapper view used when navigating to a post by ID only (e.g. push notification deep link).
/// Fetches the full post from the service before displaying PostDetailView.
struct PostDetailByIdView: View {
    let postId: String
    let onTapAuthor: (String, String) -> Void
    @EnvironmentObject var authState: AuthState
    @State private var post: Post?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let binding = Binding($post) {
                PostDetailView(post: binding, onTapAuthor: onTapAuthor)
            } else if loadFailed {
                Text("Failed to load post.")
                    .foregroundColor(.textSecondary)
                    .padding()
            } else {
                ProgressView()
            }
        }
        .task { await loadPost() }
    }

    private func loadPost() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }
        do {
            post = try await PostService.shared.getPost(
                postId: postId,
                token: token,
                userId: userId
            )
        } catch {
            loadFailed = true
        }
    }
}
