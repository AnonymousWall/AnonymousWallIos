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
    
    private var currentSortDisplayName: String {
        switch viewModel.selectedSegment {
        case 0: return viewModel.postSortOrder.displayName
        case 1: return viewModel.commentSortOrder.displayName
        case 2: return viewModel.internshipSortOrder.displayName
        default: return viewModel.marketplaceSortOrder.displayName
        }
    }
    
    private var selectedSegmentName: String {
        switch viewModel.selectedSegment {
        case 0: return "Posts"
        case 1: return "Comments"
        case 2: return "Internships"
        default: return "Marketplace"
        }
    }

    @ViewBuilder
    private func sortMenuButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                if isSelected { Image(systemName: "checkmark") }
            }
        }
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            VStack(spacing: 0) {
                // Password setup alert banner
                if authState.needsPasswordSetup {
                    PasswordSetupBannerView {
                        coordinator.navigate(to: .setPassword)
                    }
                }
                
                // User info section
                VStack(spacing: 12) {
                    // Avatar with gradient background
                    ZStack {
                        Circle()
                            .fill(LinearGradient.brandGradient)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.accentPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Profile avatar")
                    
                    if let email = authState.currentUser?.email {
                        Text(email)
                            .font(.displayLarge)
                            .foregroundColor(.textPrimary)
                            .accessibilityLabel("Email: \(email)")
                    }
                    
                    if let profileName = authState.currentUser?.profileName {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.accentBlue)
                            Text(profileName)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.accentBlue.opacity(0.15))
                        .cornerRadius(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Profile name: \(profileName)")
                    }
                }
                .padding(.vertical, 20)
                
                // Segment control
                Picker("Content Type", selection: $viewModel.selectedSegment) {
                    Text("Posts").tag(0)
                    Text("Comments").tag(1)
                    Text("Internships").tag(2)
                    Text("Marketplace").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                .accessibilityLabel("Content type")
                .accessibilityValue(selectedSegmentName)
                .onChange(of: viewModel.selectedSegment) { _, _ in
                    viewModel.segmentChanged(authState: authState)
                }
                
                // Sorting dropdown menu
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    Menu {
                        if viewModel.selectedSegment == 0 {
                            ForEach(SortOrder.feedOptions, id: \.self) { option in
                                sortMenuButton(title: option.displayName, isSelected: viewModel.postSortOrder == option) {
                                    viewModel.postSortOrder = option
                                    viewModel.postSortChanged(authState: authState)
                                }
                            }
                        } else if viewModel.selectedSegment == 1 {
                            sortMenuButton(title: SortOrder.newest.displayName, isSelected: viewModel.commentSortOrder == .newest) {
                                viewModel.commentSortOrder = .newest
                                viewModel.commentSortChanged(authState: authState)
                            }
                            sortMenuButton(title: SortOrder.oldest.displayName, isSelected: viewModel.commentSortOrder == .oldest) {
                                viewModel.commentSortOrder = .oldest
                                viewModel.commentSortChanged(authState: authState)
                            }
                        } else if viewModel.selectedSegment == 2 {
                            sortMenuButton(title: SortOrder.newest.displayName, isSelected: viewModel.internshipSortOrder == .newest) {
                                viewModel.internshipSortOrder = .newest
                                viewModel.internshipSortChanged(authState: authState)
                            }
                            sortMenuButton(title: SortOrder.oldest.displayName, isSelected: viewModel.internshipSortOrder == .oldest) {
                                viewModel.internshipSortOrder = .oldest
                                viewModel.internshipSortChanged(authState: authState)
                            }
                        } else {
                            sortMenuButton(title: SortOrder.newest.displayName, isSelected: viewModel.marketplaceSortOrder == .newest) {
                                viewModel.marketplaceSortOrder = .newest
                                viewModel.marketplaceSortChanged(authState: authState)
                            }
                            sortMenuButton(title: SortOrder.oldest.displayName, isSelected: viewModel.marketplaceSortOrder == .oldest) {
                                viewModel.marketplaceSortOrder = .oldest
                                viewModel.marketplaceSortChanged(authState: authState)
                            }
                        }
                    } label: {
                        HStack {
                            Text(currentSortDisplayName)
                                .foregroundColor(.accentPurple)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.accentPurple)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.surfaceSecondary)
                        .cornerRadius(8)
                    }
                    .accessibilityLabel("Sort by")
                    .accessibilityValue(currentSortDisplayName)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Content area
                ScrollView {
                    Group {
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView("Loading...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                        .transition(.opacity)
                    } else if viewModel.selectedSegment == 0 {
                        // Posts section
                        if viewModel.myPosts.isEmpty {
                            ProfileEmptyStateView(
                                gradient: Color.orangePinkGradient,
                                icon: "bubble.left.and.bubble.right.fill",
                                title: "No posts yet",
                                subtitle: "Create your first post!"
                            )
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
                                    .accessibilityLabel("View your post: \(post.title)")
                                    .accessibilityHint("Double tap to view full post and comments")
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
                    } else if viewModel.selectedSegment == 1 {
                        // Comments section
                        if viewModel.myComments.isEmpty {
                            ProfileEmptyStateView(
                                gradient: LinearGradient.brandGradient,
                                icon: "bubble.left.fill",
                                title: "No comments yet",
                                subtitle: "Start commenting on posts!"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.myComments) { comment in
                                    // ✅ NEW: Handle different parent types
                                    if let parent = viewModel.commentParentMap[comment.postId] {
                                        Button {
                                            switch parent {
                                            case .post(let post):
                                                coordinator.navigate(to: .postDetail(post))
                                            case .internship(let internship):
                                                coordinator.navigate(to: .internshipDetail(internship))
                                            case .marketplace(let item):
                                                coordinator.navigate(to: .marketplaceDetail(item))
                                            }
                                        } label: {
                                            ProfileCommentRowView(
                                                comment: comment,
                                                parentType: comment.parentType ?? "POST"
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .onAppear {
                                            viewModel.loadMoreCommentsIfNeeded(for: comment, authState: authState)
                                        }
                                    } else {
                                        // Show comment even if parent not loaded yet
                                        ProfileCommentRowView(
                                            comment: comment,
                                            parentType: comment.parentType ?? "POST"
                                        )
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
                    } else if viewModel.selectedSegment == 2 {
                        // Internships section
                        if viewModel.myInternships.isEmpty {
                            ProfileEmptyStateView(
                                gradient: LinearGradient.brandGradient,
                                icon: "briefcase.fill",
                                title: "No internship postings yet",
                                subtitle: "Post your first internship opportunity!"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.myInternships) { internship in
                                    Button {
                                        coordinator.navigate(to: .internshipDetail(internship))
                                    } label: {
                                        InternshipRowView(
                                            internship: internship,
                                            isOwnPosting: true,
                                            onDelete: { viewModel.deleteInternship(internship, authState: authState) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel("View your internship: \(internship.company) - \(internship.role)")
                                    .accessibilityHint("Double tap to view internship details and comments")
                                    .onAppear {
                                        viewModel.loadMoreInternshipsIfNeeded(for: internship, authState: authState)
                                    }
                                }
                                
                                // Loading indicator at bottom
                                if viewModel.isLoadingMoreInternships {
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
                        // Marketplace section
                        if viewModel.myMarketplaceItems.isEmpty {
                            ProfileEmptyStateView(
                                gradient: Color.orangePinkGradient,
                                icon: "bag.fill",
                                title: "No marketplace listings yet",
                                subtitle: "List your first item for sale!"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.myMarketplaceItems) { item in
                                    Button {
                                        coordinator.navigate(to: .marketplaceDetail(item))
                                    } label: {
                                        MarketplaceRowView(
                                            item: item,
                                            isOwnItem: true,
                                            onDelete: { viewModel.deleteMarketplaceItem(item, authState: authState) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel("View your listing: \(item.title)")
                                    .accessibilityHint("Double tap to view listing details and comments")
                                    .onAppear {
                                        viewModel.loadMoreMarketplaceItemsIfNeeded(for: item, authState: authState)
                                    }
                                }
                                
                                // Loading indicator at bottom
                                if viewModel.isLoadingMoreMarketplaceItems {
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
                    .animation(Animations.normal, value: viewModel.selectedSegment)
                    .animation(Animations.normal, value: viewModel.isLoading)
                }
                .refreshable {
                    await viewModel.refreshContent(authState: authState)
                }

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Text(errorMessage)
                            .foregroundColor(.accentRed)
                            .font(.captionMedium)
                        Spacer()
                        Button {
                            viewModel.errorMessage = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.captionMedium)
                                .foregroundColor(.accentRed)
                        }
                        .accessibilityLabel("Dismiss error")
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.accentRed.opacity(Opacity.light))
                    .cornerRadius(Radius.sm)
                    .padding(.horizontal, Spacing.lg)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error: \(errorMessage). Tap to dismiss.")
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
                        PostDetailView(post: .constant(post))
                    }
                case .internshipDetail(let internship):  // ✅ Added
                    InternshipDetailView(internship: .constant(internship))
                case .marketplaceDetail(let item):  // ✅ Added
                    MarketplaceDetailView(item: .constant(item))
                case .setPassword:
                    EmptyView() // Handled as a sheet
                case .changePassword:
                    EmptyView() // Handled as a sheet
                case .editProfileName:
                    EmptyView() // Handled as a sheet
                case .blockedUsers:
                    BlockedUsersView()
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
                        
                        // Blocked users option
                        Button(action: { coordinator.navigate(to: .blockedUsers) }) {
                            Label("Blocked Users", systemImage: "hand.raised.fill")
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
                    .accessibilityLabel("Profile menu")
                    .accessibilityHint("Double tap to access profile settings")
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
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
    let parentType: String
    
    var parentBadgeColor: Color {
        switch parentType {
        case "POST": return .accentBlue
        case "INTERNSHIP": return .orange
        case "MARKETPLACE": return .green
        default: return .gray
        }
    }
    
    var parentDisplayName: String {
        switch parentType {
        case "POST": return "Post"
        case "INTERNSHIP": return "Internship"
        case "MARKETPLACE": return "Marketplace"
        default: return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Comment by Me")
                    .font(.caption)
                    .foregroundColor(.accentPurple)
                    .fontWeight(.semibold)
                
                // Badge showing parent type
                Text(parentDisplayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(parentBadgeColor)
                    .cornerRadius(6)
                
                Spacer()
                
                Text(DateFormatting.formatRelativeTime(comment.createdAt))
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Text(comment.text)
                .font(.body)
                .foregroundColor(.textPrimary)
        }
        .padding()
        .background(Color.surfacePrimary)
        .cornerRadius(10)
    }
}


#Preview {
    ProfileView(coordinator: ProfileCoordinator())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}
