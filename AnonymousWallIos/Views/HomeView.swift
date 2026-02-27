//
//  HomeView.swift
//  AnonymousWallIos
//
//  Home view showing national posts
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var coordinator: HomeCoordinator
    
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
                            .foregroundColor(.primary)
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
                
                // Sorting segmented control
                Picker("Sort Order", selection: $viewModel.selectedSortOrder) {
                    ForEach(SortOrder.feedOptions, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .accessibilityLabel("Sort posts")
                .accessibilityValue(viewModel.selectedSortOrder.displayName)
                .onChange(of: viewModel.selectedSortOrder) { _, _ in
                    viewModel.sortOrderChanged(authState: authState)
                }
                
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
                                        .fill(Color.tealPurpleGradient)
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 30)
                                    
                                    Image(systemName: "globe.americas.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(Color.tealPurpleGradient)
                                        .accessibilityHidden(true)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("No national posts yet")
                                        .font(.title3.bold())
                                        .foregroundColor(.primary)
                                    Text("Be the first to post!")
                                        .font(.body)
                                        .foregroundColor(.secondary)
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
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("National")
            .navigationBarTitleDisplayMode(.inline)
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
                case .setPassword:
                    EmptyView() // Handled as a sheet
                }
            }
        }
        .sheet(isPresented: $coordinator.showSetPassword) {
            SetPasswordView(authService: AuthService.shared)
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
    }
}

#Preview {
    HomeView(coordinator: HomeCoordinator())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}
