//
//  ProfileViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for ProfileView - handles user profile logic
//

import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedSegment = 0
    @Published var myPosts: [Post] = []
    @Published var myComments: [Comment] = []
    @Published var commentParentMap: [String: CommentParent] = [:]  // ✅ Changed from commentPostMap
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var postSortOrder: SortOrder = .newest
    @Published var commentSortOrder: SortOrder = .newest
    
    // MARK: - Pagination State
    private var postsPagination = Pagination()
    private var commentsPagination = Pagination()
    
    @Published var isLoadingMorePosts = false
    @Published var isLoadingMoreComments = false
    
    // MARK: - Private Properties
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Dependencies
    private let userService: UserServiceProtocol
    private let postService: PostServiceProtocol
    private let internshipService: InternshipServiceProtocol  // ✅ Added
    private let marketplaceService: MarketplaceServiceProtocol  // ✅ Added
    
    // MARK: - Initialization
    init(
        userService: UserServiceProtocol = UserService.shared,
        postService: PostServiceProtocol = PostService.shared,
        internshipService: InternshipServiceProtocol = InternshipService.shared,  // ✅ Added
        marketplaceService: MarketplaceServiceProtocol = MarketplaceService.shared  // ✅ Added
    ) {
        self.userService = userService
        self.postService = postService
        self.internshipService = internshipService
        self.marketplaceService = marketplaceService
    }
    
    // MARK: - Public Methods
    func loadContent(authState: AuthState) {
        loadTask?.cancel()
        loadTask = Task {
            if selectedSegment == 0 {
                await loadPosts(authState: authState)
            } else {
                await loadComments(authState: authState)
            }
        }
    }
    
    func refreshContent(authState: AuthState) async {
        loadTask?.cancel()
        
        if selectedSegment == 0 {
            postsPagination.reset()
            await loadPosts(authState: authState)
        } else {
            commentsPagination.reset()
            await loadComments(authState: authState)
        }
    }
    
    func segmentChanged(authState: AuthState) {
        HapticFeedback.selection()
        loadTask?.cancel()
        loadTask = Task {
            if selectedSegment == 0 {
                if myPosts.isEmpty {
                    await loadPosts(authState: authState)
                }
            } else {
                if myComments.isEmpty {
                    await loadComments(authState: authState)
                }
            }
        }
    }
    
    func postSortChanged(authState: AuthState) {
        HapticFeedback.selection()
        myPosts = []
        postsPagination.reset()
        loadTask?.cancel()
        loadTask = Task {
            await loadPosts(authState: authState)
        }
    }
    
    func commentSortChanged(authState: AuthState) {
        HapticFeedback.selection()
        myComments = []
        commentParentMap = [:]  // ✅ Changed from commentPostMap
        commentsPagination.reset()
        loadTask?.cancel()
        loadTask = Task {
            await loadComments(authState: authState)
        }
    }
    
    func loadMorePostsIfNeeded(for post: Post, authState: AuthState) {
        guard !isLoadingMorePosts && postsPagination.hasMorePages else { return }
        guard post.id == myPosts.last?.id else { return }
        
        Task {
            guard !isLoadingMorePosts && postsPagination.hasMorePages else { return }
            isLoadingMorePosts = true
            await performLoadMorePosts(authState: authState)
        }
    }
    
    func loadMoreCommentsIfNeeded(for comment: Comment, authState: AuthState) {
        guard !isLoadingMoreComments && commentsPagination.hasMorePages else { return }
        guard comment.id == myComments.last?.id else { return }
        
        Task {
            guard !isLoadingMoreComments && commentsPagination.hasMorePages else { return }
            isLoadingMoreComments = true
            await performLoadMoreComments(authState: authState)
        }
    }
    
    func toggleLikePost(_ post: Post, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                let response = try await postService.toggleLike(postId: post.id, token: token, userId: userId)
                
                if let index = myPosts.firstIndex(where: { $0.id == post.id }) {
                    myPosts[index] = myPosts[index].withUpdatedLike(liked: response.liked, likes: response.likeCount)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deletePost(_ post: Post, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                _ = try await postService.hidePost(postId: post.id, token: token, userId: userId)
                postsPagination.reset()
                await loadPosts(authState: authState)
            } catch {
                errorMessage = "Failed to delete post: \(error.localizedDescription)"
            }
        }
    }
    
    func cleanup() {
        loadTask?.cancel()
    }
    
    // MARK: - Private Methods
    
    private func loadPosts(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let response = try await userService.getUserPosts(
                token: token,
                userId: userId,
                page: postsPagination.currentPage,
                limit: 20,
                sort: postSortOrder
            )
            myPosts = response.data
            postsPagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func performLoadMorePosts(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMorePosts = false
            return
        }
        
        defer {
            isLoadingMorePosts = false
        }
        
        let nextPage = postsPagination.advanceToNextPage()
        
        do {
            let response = try await userService.getUserPosts(
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: postSortOrder
            )
            
            myPosts.append(contentsOf: response.data)
            postsPagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadComments(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let response = try await userService.getUserComments(
                token: token,
                userId: userId,
                page: commentsPagination.currentPage,
                limit: 20,
                sort: commentSortOrder
            )
            myComments = response.data
            commentsPagination.update(totalPages: response.pagination.totalPages)
            
            // ✅ Load parent entities (Posts/Internships/Marketplace items)
            await loadParentsForComments(authState: authState)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func performLoadMoreComments(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMoreComments = false
            return
        }
        
        defer {
            isLoadingMoreComments = false
        }
        
        let nextPage = commentsPagination.advanceToNextPage()
        
        do {
            let response = try await userService.getUserComments(
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: commentSortOrder
            )
            
            myComments.append(contentsOf: response.data)
            commentsPagination.update(totalPages: response.pagination.totalPages)
            
            // ✅ Load parent entities for new comments
            await loadParentsForComments(authState: authState)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // ✅ NEW: Load parent entities for comments (Posts, Internships, Marketplace items)
    private func loadParentsForComments(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        // Group comments by parent type (default to POST for backward compatibility)
        let grouped = Dictionary(grouping: myComments) { comment in
            comment.parentType ?? "POST"
        }
        
        // Fetch Posts
        if let postComments = grouped["POST"] {
            let postIds = Set(postComments.map { $0.postId })
            let missingPostIds = postIds.filter { commentParentMap[$0] == nil }
            
            for postId in missingPostIds {
                do {
                    let post = try await postService.getPost(postId: postId, token: token, userId: userId)
                    commentParentMap[postId] = .post(post)
                } catch {
                    // Silently fail for individual fetches
                    continue
                }
            }
        }
        
        // Fetch Internships
        if let internshipComments = grouped["INTERNSHIP"] {
            let internshipIds = Set(internshipComments.map { $0.postId })
            let missingIds = internshipIds.filter { commentParentMap[$0] == nil }
            
            for internshipId in missingIds {
                do {
                    let internship = try await internshipService.getInternship(
                        internshipId: internshipId,
                        token: token,
                        userId: userId
                    )
                    commentParentMap[internshipId] = .internship(internship)
                } catch {
                    continue
                }
            }
        }
        
        // Fetch Marketplace Items
        if let marketplaceComments = grouped["MARKETPLACE"] {
            let itemIds = Set(marketplaceComments.map { $0.postId })
            let missingIds = itemIds.filter { commentParentMap[$0] == nil }
            
            for itemId in missingIds {
                do {
                    let item = try await marketplaceService.getItem(
                        itemId: itemId,
                        token: token,
                        userId: userId
                    )
                    commentParentMap[itemId] = .marketplace(item)
                } catch {
                    continue
                }
            }
        }
    }
}
