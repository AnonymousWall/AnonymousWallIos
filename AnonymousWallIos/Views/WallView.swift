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
    @State private var isLoadingMore = false
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var errorMessage: String?
    @State private var loadTask: Task<Void, Never>?
    
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
                    if isLoadingPosts && posts.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView("Loading posts...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else if posts.isEmpty && !isLoadingPosts {
                        VStack {
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
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(posts) { post in
                                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                                    NavigationLink(destination: PostDetailView(post: Binding(
                                        get: { posts[index] },
                                        set: { posts[index] = $0 }
                                    ))) {
                                        PostRowView(
                                            post: post,
                                            isOwnPost: post.author.id == authState.currentUser?.id,
                                            onLike: { toggleLike(for: post) },
                                            onDelete: { deletePost(post) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .onAppear {
                                        // Load more when the last post appears
                                        if post.id == posts.last?.id {
                                            loadMoreIfNeeded()
                                        }
                                    }
                                }
                            }
                            
                            // Loading indicator at bottom
                            if isLoadingMore {
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
                    await refreshPosts()
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
                    // Reset pagination and reload from first page
                    resetPagination()
                    await loadPosts()
                }
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
            loadTask = Task {
                await loadPosts()
            }
        }
        .onDisappear {
            // Cancel any ongoing load task when view disappears
            loadTask?.cancel()
        }
    }
    
    // MARK: - Functions
    
    /// Reset pagination to initial state
    private func resetPagination() {
        currentPage = 1
        hasMorePages = true
    }
    
    @MainActor
    private func refreshPosts() async {
        // Cancel any existing load task
        loadTask?.cancel()
        
        // Reset pagination state
        resetPagination()
        
        // Create a new task that won't be cancelled by the refreshable gesture
        loadTask = Task {
            await loadPosts()
        }
        
        // Wait for the task to complete
        await loadTask?.value
    }
    
    @MainActor
    private func loadPosts() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        // Set loading state for initial load or refresh
        isLoadingPosts = true
        errorMessage = nil
        
        // Ensure loading state is always reset
        defer {
            isLoadingPosts = false
        }
        
        do {
            let response = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                page: currentPage,
                limit: 20
            )
            // Replace posts (used for initial load and refresh)
            posts = response.data
            
            // Update pagination state
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            // Silently handle cancellation - this is expected behavior
            return
        } catch NetworkError.cancelled {
            // Silently handle network cancellation - this is expected behavior during refresh
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadMoreIfNeeded() {
        guard !isLoadingMore && hasMorePages else { return }
        
        Task { @MainActor in
            // Check again inside the task to prevent race condition
            guard !isLoadingMore && hasMorePages else { return }
            
            isLoadingMore = true
            await loadMorePosts()
        }
    }
    
    @MainActor
    private func loadMorePosts() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMore = false
            return
        }
        
        defer {
            isLoadingMore = false
        }
        
        // Calculate next page
        let nextPage = currentPage + 1
        
        do {
            let response = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20
            )
            
            // Update page number only after successful response
            currentPage = nextPage
            
            // Append new posts
            posts.append(contentsOf: response.data)
            
            // Update pagination state
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            // Don't update page number on cancellation
            return
        } catch NetworkError.cancelled {
            // Don't update page number on cancellation
            return
        } catch {
            // Don't update page number on error
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
                let response = try await PostService.shared.toggleLike(postId: post.id, token: token, userId: userId)
                
                // Update the post locally using the response data
                await MainActor.run {
                    if let index = posts.firstIndex(where: { $0.id == post.id }) {
                        posts[index] = posts[index].withUpdatedLike(liked: response.liked, likes: response.likeCount)
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deletePost(_ post: Post) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to delete post."
            return
        }
        
        Task {
            do {
                _ = try await PostService.shared.hidePost(postId: post.id, token: token, userId: userId)
                // Reload posts to remove the deleted post from the list
                resetPagination()
                await loadPosts()
            } catch {
                await MainActor.run {
                    // Provide user-friendly error message
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .unauthorized:
                            errorMessage = "Session expired. Please log in again."
                        case .forbidden:
                            errorMessage = "You don't have permission to delete this post."
                        case .notFound:
                            errorMessage = "Post not found."
                        case .noConnection:
                            errorMessage = "No internet connection. Please check your network."
                        default:
                            errorMessage = "Failed to delete post. Please try again."
                        }
                    } else {
                        errorMessage = "Failed to delete post. Please try again."
                    }
                }
            }
        }
    }
}

#Preview {
    WallView()
        .environmentObject(AuthState())
}
