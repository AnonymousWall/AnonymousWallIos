//
//  WallView.swift
//  AnonymousWallIos
//
//  Main wall view for authenticated users
//

import SwiftUI

struct WallView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSetPassword = false
    @State private var showChangePassword = false
    @State private var showCreatePost = false
    @State private var posts: [Post] = []
    @State private var isLoadingPosts = false
    @State private var errorMessage: String?
    
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
                if isLoadingPosts && posts.isEmpty {
                    Spacer()
                    ProgressView("Loading posts...")
                    Spacer()
                } else if posts.isEmpty && !isLoadingPosts {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No posts yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Be the first to post!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(posts) { post in
                                PostRowView(
                                    post: post,
                                    isOwnPost: post.author.id == authState.currentUser?.id,
                                    onLike: { toggleLike(for: post) },
                                    onDelete: { /* Delete not supported by API */ }
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadPosts()
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
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
                Task {
                    await loadPosts()
                }
            })
        }
        .onAppear {
            // Show password setup if needed
            // Small delay to allow view to fully load before presenting sheet
            if authState.needsPasswordSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSetPassword = true
                }
            }
            
            // Load posts
            Task {
                await loadPosts()
            }
        }
    }
    
    // MARK: - Functions
    
    @MainActor
    private func loadPosts() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        isLoadingPosts = true
        errorMessage = nil
        
        do {
            let response = try await PostService.shared.fetchPosts(token: token, userId: userId)
            posts = response.data
            isLoadingPosts = false
        } catch {
            isLoadingPosts = false
            errorMessage = error.localizedDescription
        }
    }
    
    private func toggleLike(for post: Post) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                _ = try await PostService.shared.toggleLike(postId: post.id, token: token, userId: userId)
                // Reload posts to get updated like status
                await loadPosts()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    WallView()
        .environmentObject(AuthState())
}
