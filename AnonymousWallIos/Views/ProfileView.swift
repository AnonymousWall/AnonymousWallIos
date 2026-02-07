//
//  ProfileView.swift
//  AnonymousWallIos
//
//  Profile view showing user's own posts and comments
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authState: AuthState
    @State private var selectedSegment = 0
    @State private var myPosts: [Post] = []
    @State private var myComments: [Comment] = []
    @State private var commentPostMap: [String: Post] = [:] // Map comment postId to Post
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showChangePassword = false
    @State private var showSetPassword = false
    @State private var showEditProfileName = false
    @State private var loadTask: Task<Void, Never>?
    @State private var postSortOrder: SortOrder = .newest
    @State private var commentSortOrder: SortOrder = .newest
    
    // Pagination state for posts
    @State private var currentPostsPage = 1
    @State private var hasMorePosts = true
    @State private var isLoadingMorePosts = false
    
    // Pagination state for comments
    @State private var currentCommentsPage = 1
    @State private var hasMoreComments = true
    @State private var isLoadingMoreComments = false
    
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
                
                // User info section
                VStack(spacing: 12) {
                    // Avatar with gradient background
                    ZStack {
                        Circle()
                            .fill(Color.purplePinkGradient)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.primaryPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                    }
                    
                    if let email = authState.currentUser?.email {
                        Text(email)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    if let profileName = authState.currentUser?.profileName {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.vibrantTeal)
                            Text(profileName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.vibrantTeal.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
                .padding(.vertical, 20)
                
                // Segment control
                Picker("Content Type", selection: $selectedSegment) {
                    Text("Posts").tag(0)
                    Text("Comments").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                .onChange(of: selectedSegment) { _, _ in
                    HapticFeedback.selection()
                    loadTask?.cancel()
                    resetPagination()
                    loadTask = Task {
                        await loadContent()
                    }
                }
                
                // Sorting dropdown menu
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        if selectedSegment == 0 {
                            // Posts sorting options
                            ForEach(SortOrder.feedOptions, id: \.self) { option in
                                Button {
                                    postSortOrder = option
                                    loadTask?.cancel()
                                    resetPagination()
                                    loadTask = Task {
                                        await loadContent()
                                    }
                                } label: {
                                    HStack {
                                        Text(option.displayName)
                                        if postSortOrder == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } else {
                            // Comments sorting options - only newest/oldest supported
                            Button {
                                commentSortOrder = .newest
                                loadTask?.cancel()
                                resetPagination()
                                loadTask = Task {
                                    await loadContent()
                                }
                            } label: {
                                HStack {
                                    Text(SortOrder.newest.displayName)
                                    if commentSortOrder == .newest {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button {
                                commentSortOrder = .oldest
                                loadTask?.cancel()
                                resetPagination()
                                loadTask = Task {
                                    await loadContent()
                                }
                            } label: {
                                HStack {
                                    Text(SortOrder.oldest.displayName)
                                    if commentSortOrder == .oldest {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedSegment == 0 ? postSortOrder.displayName : commentSortOrder.displayName)
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Content area
                ScrollView {
                    if isLoading {
                        VStack {
                            Spacer()
                            ProgressView("Loading...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else if selectedSegment == 0 {
                        // Posts section
                        if myPosts.isEmpty {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orangePinkGradient)
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 30)
                                    
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(Color.orangePinkGradient)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("No posts yet")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("Create your first post!")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(myPosts) { post in
                                    NavigationLink(destination: PostDetailView(post: post)) {
                                        PostRowView(
                                            post: post,
                                            isOwnPost: true,
                                            onLike: { toggleLike(for: post) },
                                            onDelete: { deletePost(post) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .onAppear {
                                        // Load more when the last post appears
                                        if post.id == myPosts.last?.id {
                                            loadMorePostsIfNeeded()
                                        }
                                    }
                                }
                                
                                // Loading indicator at bottom
                                if isLoadingMorePosts {
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
                    } else {
                        // Comments section
                        if myComments.isEmpty {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color.tealPurpleGradient)
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 30)
                                    
                                    Image(systemName: "bubble.left.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(Color.tealPurpleGradient)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("No comments yet")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("Start commenting on posts!")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(myComments) { comment in
                                    if let post = commentPostMap[comment.postId] {
                                        NavigationLink(destination: PostDetailView(post: post)) {
                                            ProfileCommentRowView(comment: comment)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .onAppear {
                                            // Load more when the last comment appears
                                            if comment.id == myComments.last?.id {
                                                loadMoreCommentsIfNeeded()
                                            }
                                        }
                                    } else {
                                        ProfileCommentRowView(comment: comment)
                                            .onAppear {
                                                // Load more when the last comment appears
                                                if comment.id == myComments.last?.id {
                                                    loadMoreCommentsIfNeeded()
                                                }
                                            }
                                    }
                                }
                                
                                // Loading indicator at bottom
                                if isLoadingMoreComments {
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
                }
                .refreshable {
                    await refreshContent()
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Edit profile name option
                        Button(action: { showEditProfileName = true }) {
                            Label("Edit Profile Name", systemImage: "person.text.rectangle")
                        }
                        
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
        .sheet(isPresented: $showEditProfileName) {
            EditProfileNameView()
        }
        .onAppear {
            // Show password setup if needed (only once)
            if authState.needsPasswordSetup && !authState.hasShownPasswordSetup {
                authState.markPasswordSetupShown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSetPassword = true
                }
            }
            
            // Load content
            loadTask = Task {
                await loadContent()
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
        if selectedSegment == 0 {
            // Reset posts pagination
            currentPostsPage = 1
            hasMorePosts = true
            myPosts = []
        } else {
            // Reset comments pagination
            currentCommentsPage = 1
            hasMoreComments = true
            myComments = []
            commentPostMap = [:]
        }
    }
    
    @MainActor
    private func refreshContent() async {
        loadTask?.cancel()
        resetPagination()
        loadTask = Task {
            await loadContent()
        }
        await loadTask?.value
    }
    
    @MainActor
    private func loadContent() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        if selectedSegment == 0 {
            // Load user's posts
            await loadMyPosts(token: token, userId: userId)
        } else {
            // Load user's comments (we'll need to fetch all posts and their comments)
            await loadMyComments(token: token, userId: userId)
        }
    }
    
    @MainActor
    private func loadMyPosts(token: String, userId: String) async {
        var campusPosts: [Post] = []
        var nationalPosts: [Post] = []
        var campusCancelled = false
        var nationalCancelled = false
        
        // Fetch campus posts for current page
        do {
            let campusResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                page: currentPostsPage,
                limit: 20,
                sort: postSortOrder
            )
            campusPosts = campusResponse.data.filter { $0.author.id == userId }
        } catch is CancellationError {
            campusCancelled = true
        } catch NetworkError.cancelled {
            campusCancelled = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        // Fetch national posts for current page
        do {
            let nationalResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                page: currentPostsPage,
                limit: 20,
                sort: postSortOrder
            )
            nationalPosts = nationalResponse.data.filter { $0.author.id == userId }
        } catch is CancellationError {
            nationalCancelled = true
        } catch NetworkError.cancelled {
            nationalCancelled = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        // If both fetches were cancelled, keep existing state
        if campusCancelled && nationalCancelled {
            return
        }
        
        // Merge posts from both walls
        let allPosts = campusPosts + nationalPosts
        
        // Apply selected sort order to merged results
        let sortedPosts: [Post]
        switch postSortOrder {
        case .newest:
            sortedPosts = allPosts.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            sortedPosts = allPosts.sorted { $0.createdAt < $1.createdAt }
        case .mostLiked:
            sortedPosts = allPosts.sorted { $0.likes > $1.likes }
        case .leastLiked:
            sortedPosts = allPosts.sorted { $0.likes < $1.likes }
        }
        
        // Replace posts (used for initial load and refresh)
        myPosts = sortedPosts
        
        // Determine if there are more pages
        // We consider there are more pages if either wall returned the full page size
        hasMorePosts = campusPosts.count == 20 || nationalPosts.count == 20
    }
    
    @MainActor
    private func loadMyComments(token: String, userId: String) async {
        do {
            // Use the new user endpoint to fetch comments with pagination
            let commentResponse = try await PostService.shared.getUserComments(
                token: token,
                userId: userId,
                page: currentCommentsPage,
                limit: 20,
                sort: commentSortOrder
            )
            
            // Replace comments (used for initial load and refresh)
            myComments = commentResponse.data
            hasMoreComments = currentCommentsPage < commentResponse.pagination.totalPages
            
            // Fetch posts for these comments to enable navigation
            // Get unique post IDs from comments
            let uniquePostIds = Set(commentResponse.data.map { $0.postId })
            
            // Fetch each unique post using the single post endpoint
            var tempPostMap: [String: Post] = [:]
            for postId in uniquePostIds {
                do {
                    let post = try await PostService.shared.getPost(
                        postId: postId,
                        token: token,
                        userId: userId
                    )
                    tempPostMap[postId] = post
                } catch is CancellationError {
                    continue
                } catch NetworkError.cancelled {
                    continue
                } catch {
                    // Continue even if some post fetches fail
                    continue
                }
            }
            
            commentPostMap = tempPostMap
            
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
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
                
                // Update the post locally without reloading the entire list
                await MainActor.run {
                    if let index = myPosts.firstIndex(where: { $0.id == post.id }) {
                        let updatedLikes = response.liked ? myPosts[index].likes + 1 : myPosts[index].likes - 1
                        myPosts[index] = myPosts[index].withUpdatedLike(liked: response.liked, likes: updatedLikes)
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
                await loadMyPosts(token: token, userId: userId)
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
    
    // MARK: - Pagination Functions
    
    private func loadMorePostsIfNeeded() {
        guard !isLoadingMorePosts && hasMorePosts else { return }
        
        Task { @MainActor in
            // Check again inside the task to prevent race condition
            guard !isLoadingMorePosts && hasMorePosts else { return }
            
            isLoadingMorePosts = true
            await loadMorePosts()
        }
    }
    
    @MainActor
    private func loadMorePosts() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMorePosts = false
            return
        }
        
        defer {
            isLoadingMorePosts = false
        }
        
        // Calculate next page
        let nextPage = currentPostsPage + 1
        
        var campusPosts: [Post] = []
        var nationalPosts: [Post] = []
        
        // Fetch campus posts for next page
        do {
            let campusResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                page: nextPage,
                limit: 20,
                sort: postSortOrder
            )
            campusPosts = campusResponse.data.filter { $0.author.id == userId }
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        
        // Fetch national posts for next page
        do {
            let nationalResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                page: nextPage,
                limit: 20,
                sort: postSortOrder
            )
            nationalPosts = nationalResponse.data.filter { $0.author.id == userId }
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        
        // Merge new posts from both walls
        let newPosts = campusPosts + nationalPosts
        
        // Apply selected sort order to new posts
        let sortedNewPosts: [Post]
        switch postSortOrder {
        case .newest:
            sortedNewPosts = newPosts.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            sortedNewPosts = newPosts.sorted { $0.createdAt < $1.createdAt }
        case .mostLiked:
            sortedNewPosts = newPosts.sorted { $0.likes > $1.likes }
        case .leastLiked:
            sortedNewPosts = newPosts.sorted { $0.likes < $1.likes }
        }
        
        // Update page number only after successful response
        currentPostsPage = nextPage
        
        // Append new posts
        myPosts.append(contentsOf: sortedNewPosts)
        
        // Update hasMorePosts flag
        hasMorePosts = campusPosts.count == 20 || nationalPosts.count == 20
    }
    
    private func loadMoreCommentsIfNeeded() {
        guard !isLoadingMoreComments && hasMoreComments else { return }
        
        Task { @MainActor in
            // Check again inside the task to prevent race condition
            guard !isLoadingMoreComments && hasMoreComments else { return }
            
            isLoadingMoreComments = true
            await loadMoreComments()
        }
    }
    
    @MainActor
    private func loadMoreComments() async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMoreComments = false
            return
        }
        
        defer {
            isLoadingMoreComments = false
        }
        
        // Calculate next page
        let nextPage = currentCommentsPage + 1
        
        do {
            // Use the new user endpoint to fetch more comments
            let commentResponse = try await PostService.shared.getUserComments(
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: commentSortOrder
            )
            
            // Update page number only after successful response
            currentCommentsPage = nextPage
            
            // Append new comments
            myComments.append(contentsOf: commentResponse.data)
            hasMoreComments = currentCommentsPage < commentResponse.pagination.totalPages
            
            // Fetch posts for new comments to enable navigation
            let uniquePostIds = Set(commentResponse.data.map { $0.postId })
            
            // Fetch each unique post that we don't already have using the single post endpoint
            for postId in uniquePostIds where commentPostMap[postId] == nil {
                do {
                    let post = try await PostService.shared.getPost(
                        postId: postId,
                        token: token,
                        userId: userId
                    )
                    commentPostMap[postId] = post
                } catch {
                    // Continue even if some post fetches fail
                    continue
                }
            }
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Simple comment row view component for profile
struct ProfileCommentRowView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Comment by Me")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                Spacer()
                Text(DateFormatting.formatRelativeTime(comment.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Text(comment.text)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthState())
}
