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
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    if let email = authState.currentUser?.email {
                        Text(email)
                            .font(.headline)
                    }
                    
                    Text("Anonymous User")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Segment control
                Picker("Content Type", selection: $selectedSegment) {
                    Text("Posts").tag(0)
                    Text("Comments").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                .onChange(of: selectedSegment) { _, _ in
                    Task {
                        await loadContent()
                    }
                }
                
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
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No posts yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Create your first post!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
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
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No comments yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Start commenting on posts!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
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
                    await loadContent()
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
        .onAppear {
            // Show password setup if needed
            if authState.needsPasswordSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSetPassword = true
                }
            }
            
            Task {
                await loadContent()
            }
        }
    }
    
    // MARK: - Functions
    
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
        do {
            // Fetch campus posts
            let campusResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                limit: 100
            )
            
            // Fetch national posts
            let nationalResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                limit: 100
            )
            
            // Filter to only show user's own posts
            let allPosts = campusResponse.data + nationalResponse.data
            myPosts = allPosts.filter { $0.author.id == userId }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func loadMyComments(token: String, userId: String) async {
        do {
            // Fetch campus posts
            let campusResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                limit: 100
            )
            
            // Fetch national posts
            let nationalResponse = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .national,
                limit: 100
            )
            
            // Fetch comments for all posts and filter user's comments
            let allPosts = campusResponse.data + nationalResponse.data
            var allComments: [Comment] = []
            var postMap: [String: Post] = [:]
            
            // First, populate the post map with all posts
            for post in allPosts {
                postMap[post.id] = post
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
                } catch {
                    // Continue even if some comment fetches fail
                    continue
                }
            }
            
            // Filter to only show user's own comments
            myComments = allComments.filter { $0.author.id == userId }
                .sorted { $0.createdAt > $1.createdAt }
            
            // Update the comment-to-post mapping
            commentPostMap = postMap
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
                _ = try await PostService.shared.toggleLike(postId: post.id, token: token, userId: userId)
                await loadMyPosts(token: token, userId: userId)
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
                Text("Comment on Post #\(comment.postId)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(comment.createdAt)
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
