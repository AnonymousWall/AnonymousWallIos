//
//  CampusView.swift
//  AnonymousWallIos
//
//  Campus view showing campus posts
//

import SwiftUI

struct CampusView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @StateObject private var viewModel = CampusViewModel()
    @ObservedObject var coordinator: CampusCoordinator
    @State private var showSortPicker = false

    // Minimum height for scrollable content when list is empty
    private let minimumScrollableHeight: CGFloat = 300
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            VStack(spacing: 0) {
                // Password setup alert banner
                if authState.needsPasswordSetup {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Please set up your password to secure your account")
                            .font(.caption)
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button("Set Now") {
                            coordinator.navigate(to: .setPassword)
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
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
                        VStack {
                            Spacer()
                            ProgressView("Loading posts...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else if viewModel.posts.isEmpty && !viewModel.isLoadingPosts {
                        VStack {
                            Spacer()
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.brandGradient)
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 30)
                                    
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(LinearGradient.brandGradient)
                                        .accessibilityHidden(true)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("No campus posts yet")
                                        .font(.title3.bold())
                                        .foregroundColor(.textPrimary)
                                    Text("Be the first to post!")
                                        .font(.body)
                                        .foregroundColor(.textSecondary)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("No campus posts yet. Be the first to post!")
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
            .navigationTitle("Campus")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CampusCoordinator.Destination.self) { destination in
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
                case .setPassword:
                    EmptyView() // Handled as a sheet
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $coordinator.showSetPassword) {
            SetPasswordView(authService: AuthService.shared)
        }
        .sheet(isPresented: $showSortPicker) {
            SortPickerSheet(selectedSort: $viewModel.selectedSortOrder)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
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
        }
        .onDisappear {
            // Cancel any ongoing load task when view disappears
            viewModel.cleanup()
        }
        .onReceive(blockViewModel.userBlockedPublisher) { blockedUserId in
            viewModel.removePostsFromUser(blockedUserId)
        }
    }
}

#Preview {
    CampusView(coordinator: CampusCoordinator())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}
