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
    @Published var commentPostMap: [String: Post] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var postSortOrder: SortOrder = .newest
    @Published var commentSortOrder: SortOrder = .newest
    
    // MARK: - Pagination State
    @Published var currentPostsPage = 1
    @Published var hasMorePosts = true
    @Published var isLoadingMorePosts = false
    
    @Published var currentCommentsPage = 1
    @Published var hasMoreComments = true
    @Published var isLoadingMoreComments = false
    
    // MARK: - Private Properties
    private var loadTask: Task<Void, Never>?
    
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
            resetPostsPagination()
            await loadPosts(authState: authState)
        } else {
            resetCommentsPagination()
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
        resetPostsPagination()
        loadTask?.cancel()
        loadTask = Task {
            await loadPosts(authState: authState)
        }
    }
    
    func commentSortChanged(authState: AuthState) {
        HapticFeedback.selection()
        myComments = []
        commentPostMap = [:]
        resetCommentsPagination()
        loadTask?.cancel()
        loadTask = Task {
            await loadComments(authState: authState)
        }
    }
    
    func loadMorePostsIfNeeded(for post: Post, authState: AuthState) {
        guard !isLoadingMorePosts && hasMorePosts else { return }
        guard post.id == myPosts.last?.id else { return }
        
        Task {
            guard !isLoadingMorePosts && hasMorePosts else { return }
            isLoadingMorePosts = true
            await performLoadMorePosts(authState: authState)
        }
    }
    
    func loadMoreCommentsIfNeeded(for comment: Comment, authState: AuthState) {
        guard !isLoadingMoreComments && hasMoreComments else { return }
        guard comment.id == myComments.last?.id else { return }
        
        Task {
            guard !isLoadingMoreComments && hasMoreComments else { return }
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
                let response = try await PostService.shared.toggleLike(postId: post.id, token: token, userId: userId)
                
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
                _ = try await PostService.shared.hidePost(postId: post.id, token: token, userId: userId)
                resetPostsPagination()
                await loadPosts(authState: authState)
            } catch {
                errorMessage = "Failed to delete post: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteComment(_ comment: Comment, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id,
              let post = commentPostMap[comment.postId] else {
            return
        }
        
        Task {
            do {
                _ = try await PostService.shared.hideComment(postId: post.id, commentId: comment.id, token: token, userId: userId)
                resetCommentsPagination()
                await loadComments(authState: authState)
            } catch {
                errorMessage = "Failed to delete comment: \(error.localizedDescription)"
            }
        }
    }
    
    func cleanup() {
        loadTask?.cancel()
    }
    
    // MARK: - Private Methods
    private func resetPostsPagination() {
        currentPostsPage = 1
        hasMorePosts = true
    }
    
    private func resetCommentsPagination() {
        currentCommentsPage = 1
        hasMoreComments = true
    }
    
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
            let response = try await PostService.shared.getUserPosts(
                token: token,
                userId: userId,
                page: currentPostsPage,
                limit: 20,
                sort: postSortOrder
            )
            myPosts = response.data
            hasMorePosts = currentPostsPage < response.pagination.totalPages
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
        
        let nextPage = currentPostsPage + 1
        
        do {
            let response = try await PostService.shared.getUserPosts(
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: postSortOrder
            )
            
            currentPostsPage = nextPage
            myPosts.append(contentsOf: response.data)
            hasMorePosts = currentPostsPage < response.pagination.totalPages
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
            let response = try await PostService.shared.getUserComments(
                token: token,
                userId: userId,
                page: currentCommentsPage,
                limit: 20,
                sort: commentSortOrder
            )
            myComments = response.data
            hasMoreComments = currentCommentsPage < response.pagination.totalPages
            
            // Load post information for each comment
            await loadPostsForComments(authState: authState)
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
        
        let nextPage = currentCommentsPage + 1
        
        do {
            let response = try await PostService.shared.getUserComments(
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: commentSortOrder
            )
            
            currentCommentsPage = nextPage
            myComments.append(contentsOf: response.data)
            hasMoreComments = currentCommentsPage < response.pagination.totalPages
            
            // Load post information for new comments
            await loadPostsForComments(authState: authState)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadPostsForComments(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        // Get unique post IDs that we don't have yet
        let postIds = Set(myComments.map { $0.postId })
        let missingPostIds = postIds.filter { commentPostMap[$0] == nil }
        
        // Fetch missing posts
        for postId in missingPostIds {
            do {
                let post = try await PostService.shared.getPost(postId: postId, token: token, userId: userId)
                commentPostMap[postId] = post
            } catch {
                // Silently fail for individual post fetches
                continue
            }
        }
    }
}
