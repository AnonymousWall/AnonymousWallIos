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
                                    } else {
                                        ProfileCommentRowView(comment: comment)
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
    
    @MainActor
    private func refreshContent() async {
        loadTask?.cancel()
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
        
        // Fetch campus posts
        do {
            let campusResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                limit: 100
            )
            campusPosts = campusResponse.data
        } catch is CancellationError {
            campusCancelled = true
        } catch NetworkError.cancelled {
            campusCancelled = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        // Fetch national posts
        do {
            let nationalResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                limit: 100
            )
            nationalPosts = nationalResponse.data
        } catch is CancellationError {
            nationalCancelled = true
        } catch NetworkError.cancelled {
            nationalCancelled = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        // Determine if we should update posts:
        // - At least one fetch was not cancelled
        // - AND we have actual data from at least one fetch
        let hasAttemptedFetch = !campusCancelled || !nationalCancelled
        let hasActualData = !campusPosts.isEmpty || !nationalPosts.isEmpty
        let shouldUpdatePosts = hasAttemptedFetch && hasActualData
        
        if shouldUpdatePosts {
            let allPosts = campusPosts + nationalPosts
            let userPosts = allPosts.filter { $0.author.id == userId }
            
            // Apply selected sort order
            // Note: Only feedOptions (.newest, .mostLiked, .oldest) are exposed in UI
            switch postSortOrder {
            case .newest:
                myPosts = userPosts.sorted { $0.createdAt > $1.createdAt }
            case .oldest:
                myPosts = userPosts.sorted { $0.createdAt < $1.createdAt }
            case .mostLiked:
                myPosts = userPosts.sorted { $0.likes > $1.likes }
            case .leastLiked:
                // Not exposed in UI, but handle for completeness
                myPosts = userPosts.sorted { $0.likes < $1.likes }
            }
        }
    }
    
    @MainActor
    private func loadMyComments(token: String, userId: String) async {
        var campusPosts: [Post] = []
        var nationalPosts: [Post] = []
        var campusCancelled = false
        var nationalCancelled = false
        
        // Fetch campus posts
        do {
            let campusResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                limit: 100
            )
            campusPosts = campusResponse.data
        } catch is CancellationError {
            campusCancelled = true
        } catch NetworkError.cancelled {
            campusCancelled = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        // Fetch national posts
        do {
            let nationalResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                limit: 100
            )
            nationalPosts = nationalResponse.data
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
        
        // Fetch comments for all posts and filter user's comments
        let allPosts = campusPosts + nationalPosts
        
        // Handle the case when we have no posts (could be due to cancellation, errors, or empty results)
        guard !allPosts.isEmpty else {
            // Only clear comments if both fetches were not cancelled (meaning they completed but returned no data)
            // Don't clear if either was cancelled, as we want to maintain existing state
            if !campusCancelled && !nationalCancelled {
                myComments = []
                commentPostMap = [:]
            }
            return
        }
        
        var allComments: [Comment] = []
        var tempPostMap: [String: Post] = [:]
        
        // First, populate the post map with all posts
        for post in allPosts {
            tempPostMap[post.id] = post
        }
        
        // Then fetch comments
        for post in allPosts {
            do {
                let commentResponse = try await PostService.shared.getComments(
                    postId: post.id,
                    token: token,
                    userId: userId,
                    limit: 100
                )
                allComments.append(contentsOf: commentResponse.data)
            } catch is CancellationError {
                // Silently handle cancellation
                continue
            } catch NetworkError.cancelled {
                // Silently handle network cancellation
                continue
            } catch {
                // Continue even if some comment fetches fail
                continue
            }
        }
        
        // Only update UI when we have new data (non-empty collections)
        // Preserve existing state when new collections are empty
        if !tempPostMap.isEmpty {
            commentPostMap = tempPostMap
        }
        
        if !allComments.isEmpty {
            // Filter to only show user's own comments
            let userComments = allComments.filter { $0.author.id == userId }
            
            // Apply selected sort order
            // Note: Only .newest and .oldest are exposed in the UI for comments
            switch commentSortOrder {
            case .newest:
                myComments = userComments.sorted { $0.createdAt > $1.createdAt }
            case .oldest:
                myComments = userComments.sorted { $0.createdAt < $1.createdAt }
            case .mostLiked, .leastLiked:
                // Not supported for comments, default to newest
                myComments = userComments.sorted { $0.createdAt > $1.createdAt }
            }
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
