//
//  PostDetailViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for PostDetailView - handles post detail and comments logic
//

import SwiftUI

@MainActor
class PostDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var comments: [Comment] = []
    @Published var isLoadingComments = false
    @Published var isLoadingMoreComments = false
    @Published var commentText = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var commentToDelete: Comment?
    @Published var commentToReport: Comment?
    @Published var selectedSortOrder: SortOrder = .newest
    
    // MARK: - Dependencies
    private let postService: PostServiceProtocol
    
    // MARK: - Private Properties
    private var currentPage = 1
    private var hasMorePages = true
    private var loadCommentsTask: Task<Void, Never>?
    private var refreshPostTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(postService: PostServiceProtocol = PostService.shared) {
        self.postService = postService
    }
    
    // MARK: - Public Methods
    
    /// Refresh the post to get the latest comment count
    func refreshPost(post: Binding<Post>, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        // Cancel any existing refresh task
        refreshPostTask?.cancel()
        
        refreshPostTask = Task {
            do {
                let updatedPost = try await postService.getPost(postId: post.wrappedValue.id, token: token, userId: userId)
                post.wrappedValue = updatedPost
            } catch is CancellationError {
                return
            } catch NetworkError.cancelled {
                return
            } catch {
                // Silently fail - the post will still be displayed with potentially stale data
                Logger.data.warning("Failed to refresh post: \(error.localizedDescription)")
            }
        }
    }
    
    func loadComments(postId: String, authState: AuthState) {
        loadCommentsTask?.cancel()
        loadCommentsTask = Task {
            await performLoadComments(postId: postId, authState: authState)
        }
    }
    
    func refreshComments(postId: String, authState: AuthState) async {
        loadCommentsTask?.cancel()
        resetPagination()
        loadCommentsTask = Task {
            await performLoadComments(postId: postId, authState: authState)
        }
        await loadCommentsTask?.value
    }
    
    func loadMoreCommentsIfNeeded(for comment: Comment, postId: String, authState: AuthState) {
        guard !isLoadingMoreComments && hasMorePages else { return }
        guard comment.id == comments.last?.id else { return }
        
        Task {
            guard !isLoadingMoreComments && hasMorePages else { return }
            isLoadingMoreComments = true
            await performLoadMoreComments(postId: postId, authState: authState)
        }
    }
    
    func sortOrderChanged(postId: String, authState: AuthState) {
        HapticFeedback.selection()
        loadCommentsTask?.cancel()
        comments = []
        resetPagination()
        loadCommentsTask = Task {
            await performLoadComments(postId: postId, authState: authState)
        }
    }
    
    func submitComment(postId: String, authState: AuthState, post: Binding<Post>, onSuccess: @escaping () -> Void) {
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else {
            errorMessage = "Comment cannot be empty"
            return
        }
        
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await postService.addComment(postId: postId, text: trimmedText, token: token, userId: userId)
                HapticFeedback.success()
                isSubmitting = false
                commentText = ""
                
                // Update the comment count locally
                post.wrappedValue = post.wrappedValue.withUpdatedComments(comments: post.wrappedValue.comments + 1)
                
                onSuccess()
                // Reload comments to show the new one
                loadCommentsTask?.cancel()
                resetPagination()
                loadCommentsTask = Task {
                    await performLoadComments(postId: postId, authState: authState)
                }
            } catch is CancellationError {
                isSubmitting = false
                return
            } catch NetworkError.cancelled {
                isSubmitting = false
                return
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleLike(post: Binding<Post>, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                let response = try await postService.toggleLike(postId: post.wrappedValue.id, token: token, userId: userId)
                post.wrappedValue = post.wrappedValue.withUpdatedLike(liked: response.liked, likes: response.likeCount)
            } catch is CancellationError {
                return
            } catch NetworkError.cancelled {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deletePost(post: Post, authState: AuthState, onSuccess: @escaping () -> Void) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        Task {
            do {
                _ = try await postService.hidePost(postId: post.id, token: token, userId: userId)
                HapticFeedback.success()
                onSuccess()
            } catch is CancellationError {
                return
            } catch NetworkError.cancelled {
                return
            } catch {
                errorMessage = "Failed to delete post: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteComment(_ comment: Comment, postId: String, authState: AuthState, post: Binding<Post>) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        Task {
            do {
                _ = try await postService.hideComment(postId: postId, commentId: comment.id, token: token, userId: userId)
                HapticFeedback.success()
                
                // Update the comment count locally
                post.wrappedValue = post.wrappedValue.withUpdatedComments(comments: max(0, post.wrappedValue.comments - 1))
                
                // Reload comments to remove the deleted one
                loadCommentsTask?.cancel()
                resetPagination()
                loadCommentsTask = Task {
                    await performLoadComments(postId: postId, authState: authState)
                }
            } catch is CancellationError {
                return
            } catch NetworkError.cancelled {
                return
            } catch {
                errorMessage = "Failed to delete comment: \(error.localizedDescription)"
            }
        }
    }
    
    func reportPost(post: Post, reason: String?, authState: AuthState, onSuccess: @escaping () -> Void) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        Task {
            do {
                let response = try await postService.reportPost(postId: post.id, reason: reason, token: token, userId: userId)
                Logger.data.info("Post reported: \(response.message)")
                HapticFeedback.success()
                onSuccess()
            } catch is CancellationError {
                return
            } catch NetworkError.cancelled {
                return
            } catch {
                errorMessage = "Failed to report post: \(error.localizedDescription)"
            }
        }
    }
    
    func reportComment(_ comment: Comment, postId: String, reason: String?, authState: AuthState, onSuccess: @escaping () -> Void) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        Task {
            do {
                let response = try await postService.reportComment(postId: postId, commentId: comment.id, reason: reason, token: token, userId: userId)
                Logger.data.info("Comment reported: \(response.message)")
                HapticFeedback.success()
                onSuccess()
            } catch is CancellationError {
                return
            } catch NetworkError.cancelled {
                return
            } catch {
                errorMessage = "Failed to report comment: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Methods
    private func resetPagination() {
        currentPage = 1
        hasMorePages = true
    }
    
    private func performLoadComments(postId: String, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        isLoadingComments = true
        errorMessage = nil
        
        defer {
            isLoadingComments = false
        }
        
        do {
            let response = try await postService.getComments(
                postId: postId,
                token: token,
                userId: userId,
                page: currentPage,
                limit: 20,
                sort: selectedSortOrder
            )
            comments = response.data
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func performLoadMoreComments(postId: String, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMoreComments = false
            return
        }
        
        defer {
            isLoadingMoreComments = false
        }
        
        let nextPage = currentPage + 1
        
        do {
            let response = try await postService.getComments(
                postId: postId,
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: selectedSortOrder
            )
            
            currentPage = nextPage
            comments.append(contentsOf: response.data)
            hasMorePages = currentPage < response.pagination.totalPages
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
