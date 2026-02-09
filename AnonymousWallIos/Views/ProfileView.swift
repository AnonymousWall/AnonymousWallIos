//
//  ProfileView.swift
//  AnonymousWallIos
//
//  Profile view showing user's own posts and comments
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject var coordinator: ProfileCoordinator
    
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
                Picker("Content Type", selection: $viewModel.selectedSegment) {
                    Text("Posts").tag(0)
                    Text("Comments").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                .onChange(of: viewModel.selectedSegment) { _, _ in
                    viewModel.segmentChanged(authState: authState)
                }
                
                // Sorting dropdown menu
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Menu {
                        if viewModel.selectedSegment == 0 {
                            // Posts sorting options
                            ForEach(SortOrder.feedOptions, id: \.self) { option in
                                Button {
                                    viewModel.postSortOrder = option
                                    viewModel.postSortChanged(authState: authState)
                                } label: {
                                    HStack {
                                        Text(option.displayName)
                                        if viewModel.postSortOrder == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } else {
                            // Comments sorting options - only newest/oldest supported
                            Button {
                                viewModel.commentSortOrder = .newest
                                viewModel.commentSortChanged(authState: authState)
                            } label: {
                                HStack {
                                    Text(SortOrder.newest.displayName)
                                    if viewModel.commentSortOrder == .newest {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Button {
                                viewModel.commentSortOrder = .oldest
                                viewModel.commentSortChanged(authState: authState)
                            } label: {
                                HStack {
                                    Text(SortOrder.oldest.displayName)
                                    if viewModel.commentSortOrder == .oldest {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedSegment == 0 ? viewModel.postSortOrder.displayName : viewModel.commentSortOrder.displayName)
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
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView("Loading...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else if viewModel.selectedSegment == 0 {
                        // Posts section
                        if viewModel.myPosts.isEmpty {
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
                                ForEach(viewModel.myPosts) { post in
                                    Button {
                                        coordinator.navigate(to: .postDetail(post))
                                    } label: {
                                        PostRowView(
                                            post: post,
                                            isOwnPost: true,
                                            onLike: { viewModel.toggleLikePost(post, authState: authState) },
                                            onDelete: { viewModel.deletePost(post, authState: authState) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .onAppear {
                                        viewModel.loadMorePostsIfNeeded(for: post, authState: authState)
                                    }
                                }
                                
                                // Loading indicator at bottom
                                if viewModel.isLoadingMorePosts {
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
                        if viewModel.myComments.isEmpty {
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
                                ForEach(viewModel.myComments) { comment in
                                    if let post = viewModel.commentPostMap[comment.postId] {
                                        Button {
                                            coordinator.navigate(to: .postDetail(post))
                                        } label: {
                                            ProfileCommentRowView(comment: comment)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .onAppear {
                                            viewModel.loadMoreCommentsIfNeeded(for: comment, authState: authState)
                                        }
                                    } else {
                                        ProfileCommentRowView(comment: comment)
                                            .onAppear {
                                                viewModel.loadMoreCommentsIfNeeded(for: comment, authState: authState)
                                            }
                                    }
                                }
                                
                                // Loading indicator at bottom
                                if viewModel.isLoadingMoreComments {
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
                    await viewModel.refreshContent(authState: authState)
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ProfileCoordinator.Destination.self) { destination in
                switch destination {
                case .postDetail(let post):
                    if let index = viewModel.myPosts.firstIndex(where: { $0.id == post.id }) {
                        PostDetailView(post: Binding(
                            get: { viewModel.myPosts[index] },
                            set: { viewModel.myPosts[index] = $0 }
                        ))
                    } else {
                        // Fallback if post is not found in the list
                        PostDetailView(post: .constant(post))
                    }
                case .setPassword:
                    EmptyView() // Handled as a sheet
                case .changePassword:
                    EmptyView() // Handled as a sheet
                case .editProfileName:
                    EmptyView() // Handled as a sheet
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Edit profile name option
                        Button(action: { coordinator.navigate(to: .editProfileName) }) {
                            Label("Edit Profile Name", systemImage: "person.text.rectangle")
                        }
                        
                        // Change password option (only if password is set)
                        if !authState.needsPasswordSetup {
                            Button(action: { coordinator.navigate(to: .changePassword) }) {
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
        .sheet(isPresented: $coordinator.showSetPassword) {
            SetPasswordView(authService: AuthService.shared)
        }
        .sheet(isPresented: $coordinator.showChangePassword) {
            ChangePasswordView(authService: AuthService.shared)
        }
        .sheet(isPresented: $coordinator.showEditProfileName) {
            EditProfileNameView(userService: UserService.shared)
        }
        .onAppear {
            // Show password setup if needed (only once)
            if authState.needsPasswordSetup && !authState.hasShownPasswordSetup {
                authState.markPasswordSetupShown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    coordinator.navigate(to: .setPassword)
                }
            }
            
            // Load content
            viewModel.loadContent(authState: authState)
        }
        .onDisappear {
            viewModel.cleanup()
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
    ProfileView(coordinator: ProfileCoordinator())
        .environmentObject(AuthState())
}
