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
    
    // MARK: - Initialization
    init(postService: PostServiceProtocol = PostService.shared) {
        self.postService = postService
    }
    
    // MARK: - Public Methods
    func loadComments(postId: String, authState: AuthState) async {
        await performLoadComments(postId: postId, authState: authState)
    }
    
    func refreshComments(postId: String, authState: AuthState) async {
        resetPagination()
        await performLoadComments(postId: postId, authState: authState)
    }
    
    func loadMoreCommentsIfNeeded(for comment: Comment, postId: String, authState: AuthState) async {
        guard !isLoadingMoreComments && hasMorePages else { return }
        guard comment.id == comments.last?.id else { return }
        
        isLoadingMoreComments = true
        await performLoadMoreComments(postId: postId, authState: authState)
    }
    
    func sortOrderChanged(postId: String, authState: AuthState) async {
        HapticFeedback.selection()
        comments = []
        resetPagination()
        await performLoadComments(postId: postId, authState: authState)
    }
    
    func submitComment(postId: String, authState: AuthState, onSuccess: @escaping () -> Void) async {
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
        
        do {
            _ = try await postService.addComment(postId: postId, text: trimmedText, token: token, userId: userId)
            HapticFeedback.success()
            isSubmitting = false
            commentText = ""
            onSuccess()
            // Reload comments to show the new one
            resetPagination()
            await performLoadComments(postId: postId, authState: authState)
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleLike(post: Binding<Post>, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        do {
            let response = try await postService.toggleLike(postId: post.wrappedValue.id, token: token, userId: userId)
            post.wrappedValue = post.wrappedValue.withUpdatedLike(liked: response.liked, likes: response.likeCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deletePost(post: Post, authState: AuthState, onSuccess: @escaping () -> Void) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        do {
            _ = try await postService.hidePost(postId: post.id, token: token, userId: userId)
            HapticFeedback.success()
            onSuccess()
        } catch {
            errorMessage = "Failed to delete post: \(error.localizedDescription)"
        }
    }
    
    func deleteComment(_ comment: Comment, postId: String, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        do {
            _ = try await postService.hideComment(postId: postId, commentId: comment.id, token: token, userId: userId)
            HapticFeedback.success()
            // Reload comments to remove the deleted one
            resetPagination()
            await performLoadComments(postId: postId, authState: authState)
        } catch {
            errorMessage = "Failed to delete comment: \(error.localizedDescription)"
        }
    }
    
    func reportPost(post: Post, reason: String?, authState: AuthState, onSuccess: @escaping () -> Void) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        do {
            let response = try await postService.reportPost(postId: post.id, reason: reason, token: token, userId: userId)
            Logger.data.info("Post reported: \(response.message)")
            HapticFeedback.success()
            onSuccess()
        } catch {
            errorMessage = "Failed to report post: \(error.localizedDescription)"
        }
    }
    
    func reportComment(_ comment: Comment, postId: String, reason: String?, authState: AuthState, onSuccess: @escaping () -> Void) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        do {
            let response = try await postService.reportComment(postId: postId, commentId: comment.id, reason: reason, token: token, userId: userId)
            Logger.data.info("Comment reported: \(response.message)")
            HapticFeedback.success()
            onSuccess()
        } catch {
            errorMessage = "Failed to report comment: \(error.localizedDescription)"
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
