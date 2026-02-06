//
//  HomeView.swift
//  AnonymousWallIos
//
//  Home view showing national posts
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSetPassword = false
    @State private var posts: [Post] = []
    @State private var isLoadingPosts = false
    @State private var isLoadingMore = false
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var errorMessage: String?
    @State private var loadTask: Task<Void, Never>?
    @State private var selectedSortOrder: SortOrder = .newest
    
    // Minimum height for scrollable content when list is empty
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
                
                // Sorting segmented control
                Picker("Sort Order", selection: $selectedSortOrder) {
                    ForEach(SortOrder.feedOptions, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .onChange(of: selectedSortOrder) { _, _ in
                    loadTask?.cancel()
                    currentPage = 1
                    hasMorePages = true
                    loadTask = Task {
                        await loadPosts(isRefresh: true)
                    }
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
                                Image(systemName: "globe")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No national posts yet")
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
                                NavigationLink(destination: PostDetailView(post: post)) {
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
            .navigationTitle("National")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showSetPassword) {
            SetPasswordView()
        }
        .onAppear {
            // Show password setup if needed (only once)
            if authState.needsPasswordSetup && !authState.hasShownPasswordSetup {
                authState.markPasswordSetupShown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSetPassword = true
                }
            }
            
            // Load posts
            loadTask = Task {
                await loadPosts(isRefresh: true)
            }
        }
        .onDisappear {
            // Cancel any ongoing load task when view disappears
            loadTask?.cancel()
        }
    }
    
    // MARK: - Functions
    
    @MainActor
    private func refreshPosts() async {
        loadTask?.cancel()
        currentPage = 1
        hasMorePages = true
        loadTask = Task {
            await loadPosts(isRefresh: true)
        }
        await loadTask?.value
    }
    
    @MainActor
    private func loadPosts(isRefresh: Bool = false) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        if isRefresh {
            isLoadingPosts = true
        }
        errorMessage = nil
        
        defer {
            isLoadingPosts = false
        }
        
        do {
            let response = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                page: currentPage,
                limit: 20,
                sort: selectedSortOrder
            )
            // Replace posts on initial load or refresh
            posts = response.data
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
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
        
        currentPage += 1
        
        do {
            let response = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                page: currentPage,
                limit: 20,
                sort: selectedSortOrder
            )
            
            posts.append(contentsOf: response.data)
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            currentPage -= 1
            return
        } catch NetworkError.cancelled {
            currentPage -= 1
            return
        } catch {
            currentPage -= 1
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
                currentPage = 1
                hasMorePages = true
                await loadPosts(isRefresh: true)
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
                currentPage = 1
                hasMorePages = true
                await loadPosts(isRefresh: true)
            } catch {
                await MainActor.run {
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
    HomeView()
        .environmentObject(AuthState())
}
