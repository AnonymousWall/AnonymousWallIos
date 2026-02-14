//
//  WallView.swift
//  AnonymousWallIos
//
//  Main wall view for authenticated users
//

import SwiftUI

struct WallView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = WallViewModel()
    @State private var showSetPassword = false
    @State private var showChangePassword = false
    @State private var showCreatePost = false
    
    // Minimum height for scrollable content when list is empty
    // 300 points provides sufficient height to enable pull-to-refresh gesture on all device sizes
    private let minimumScrollableHeight: CGFloat = 300
    
    var body: some View {
        NavigationStack {
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
                            showSetPassword = true
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
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                    .accessibilityHidden(true)
                                Text("No posts yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Be the first to post!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("No posts yet. Be the first to post!")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.posts) { post in
                                if let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) {
                                    NavigationLink(destination: PostDetailView(post: Binding(
                                        get: { viewModel.posts[index] },
                                        set: { viewModel.posts[index] = $0 }
                                    ))) {
                                        PostRowView(
                                            post: post,
                                            isOwnPost: post.author.id == authState.currentUser?.id,
                                            onLike: { viewModel.toggleLike(for: post, authState: authState) },
                                            onDelete: { viewModel.deletePost(post, authState: authState) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel("View post: \(post.title)")
                                    .accessibilityHint("Double tap to view full post and comments")
                                    .onAppear {
                                        viewModel.loadMoreIfNeeded(for: post, authState: authState)
                                    }
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
            .navigationTitle("Wall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Create post button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                    }
                }
                
                // Menu button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Change password option (only if password is set)
                        if !authState.needsPasswordSetup {
                            Button(action: { showChangePassword = true }) {
                                Label("Change Password", systemImage: "lock.shield")
                            }
                        }
                        
                        // Logout option
                        Button(role: .destructive, action: {
                            authState.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showSetPassword) {
            SetPasswordView()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(onPostCreated: {
                viewModel.loadPosts(authState: authState)
            })
        }
        .onAppear {
            // Show password setup if needed (only once)
            // Small delay to allow view to fully load before presenting sheet
            if authState.needsPasswordSetup && !authState.hasShownPasswordSetup {
                authState.markPasswordSetupShown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSetPassword = true
                }
            }
            
            // Load posts
            viewModel.loadPosts(authState: authState)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

#Preview {
    WallView()
        .environmentObject(AuthState())
}
