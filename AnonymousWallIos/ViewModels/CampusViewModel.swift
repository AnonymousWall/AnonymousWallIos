//
//  CampusViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for CampusView - handles campus post feed business logic
//

import SwiftUI

@MainActor
class CampusViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var posts: [Post] = []
    @Published var isLoadingPosts = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedSortOrder: SortOrder = .newest
    
    // MARK: - Private Properties
    private var currentPage = 1
    private var hasMorePages = true
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Dependencies
    private let postService: PostServiceProtocol
    
    // MARK: - Initialization
    init(postService: PostServiceProtocol = PostService.shared) {
        self.postService = postService
    }
    
    // MARK: - Public Methods
    
    /// Load initial posts
    func loadPosts(authState: AuthState) {
        loadTask?.cancel()
        loadTask = Task {
            await performLoadPosts(authState: authState)
        }
    }
    
    /// Refresh posts (pull-to-refresh)
    func refreshPosts(authState: AuthState) async {
        loadTask?.cancel()
        resetPagination()
        loadTask = Task {
            await performLoadPosts(authState: authState)
        }
        await loadTask?.value
    }
    
    /// Load more posts when scrolling to the end
    func loadMoreIfNeeded(for post: Post, authState: AuthState) {
        guard !isLoadingMore && hasMorePages else { return }
        guard post.id == posts.last?.id else { return }
        
        Task {
            guard !isLoadingMore && hasMorePages else { return }
            isLoadingMore = true
            await performLoadMorePosts(authState: authState)
        }
    }
    
    /// Handle sort order change
    func sortOrderChanged(authState: AuthState) {
        HapticFeedback.selection()
        loadTask?.cancel()
        posts = [] // Clear posts to show loading indicator
        resetPagination()
        loadTask = Task {
            await performLoadPosts(authState: authState)
        }
    }
    
    /// Toggle like for a post
    func toggleLike(for post: Post, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                let response = try await postService.toggleLike(
                    postId: post.id,
                    token: token,
                    userId: userId
                )
                
                // Update the post locally using the response data
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index] = posts[index].withUpdatedLike(
                        liked: response.liked,
                        likes: response.likeCount
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Delete (hide) a post
    func deletePost(_ post: Post, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to delete post."
            return
        }
        
        Task {
            do {
                _ = try await postService.hidePost(
                    postId: post.id,
                    token: token,
                    userId: userId
                )
                // Reload posts to remove the deleted post from the list
                resetPagination()
                await performLoadPosts(authState: authState)
            } catch {
                // Provide user-friendly error message
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
    
    /// Clean up resources when view disappears
    func cleanup() {
        loadTask?.cancel()
    }
    
    // MARK: - Private Methods
    
    /// Reset pagination to initial state
    private func resetPagination() {
        currentPage = 1
        hasMorePages = true
    }
    
    /// Perform the actual post loading
    private func performLoadPosts(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        isLoadingPosts = true
        errorMessage = nil
        
        defer {
            isLoadingPosts = false
        }
        
        do {
            let response = try await postService.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                page: currentPage,
                limit: 20,
                sort: selectedSortOrder
            )
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
    
    /// Perform loading more posts for pagination
    private func performLoadMorePosts(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMore = false
            return
        }
        
        defer {
            isLoadingMore = false
        }
        
        let nextPage = currentPage + 1
        
        do {
            let response = try await postService.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                page: nextPage,
                limit: 20,
                sort: selectedSortOrder
            )
            
            currentPage = nextPage
            posts.append(contentsOf: response.data)
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
