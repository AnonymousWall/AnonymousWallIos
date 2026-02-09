//
//  PostFeedViewModel.swift
//  AnonymousWallIos
//
//  Generic ViewModel for post feed views (HomeView, CampusView)
//  Handles post loading, sorting, pagination, and actions
//

import SwiftUI

@MainActor
class PostFeedViewModel: ObservableObject {
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
    private let wallType: WallType
    
    // MARK: - Initialization
    init(wallType: WallType) {
        self.wallType = wallType
    }
    
    deinit {
        #if DEBUG
        Logger.app.debug("✅ PostFeedViewModel deinitialized")
        #endif
        cleanup()
    }
    
    // MARK: - Public Methods
    func loadPosts(authState: AuthState) {
        loadTask?.cancel()
        loadTask = Task {
            await performLoadPosts(authState: authState)
        }
    }
    
    func refreshPosts(authState: AuthState) async {
        loadTask?.cancel()
        resetPagination()
        loadTask = Task {
            await performLoadPosts(authState: authState)
        }
        await loadTask?.value
    }
    
    func loadMoreIfNeeded(for post: Post, authState: AuthState) {
        guard !isLoadingMore && hasMorePages else { return }
        guard post.id == posts.last?.id else { return }
        
        Task {
            guard !isLoadingMore && hasMorePages else { return }
            isLoadingMore = true
            await performLoadMorePosts(authState: authState)
        }
    }
    
    func sortOrderChanged(authState: AuthState) {
        HapticFeedback.selection()
        loadTask?.cancel()
        posts = [] // Clear posts to show loading indicator
        resetPagination()
        loadTask = Task {
            await performLoadPosts(authState: authState)
        }
    }
    
    func toggleLike(for post: Post, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                let response = try await PostService.shared.toggleLike(postId: post.id, token: token, userId: userId)
                
                // Update the post locally using the response data
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index] = posts[index].withUpdatedLike(liked: response.liked, likes: response.likeCount)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deletePost(_ post: Post, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to delete post."
            return
        }
        
        Task {
            do {
                _ = try await PostService.shared.hidePost(postId: post.id, token: token, userId: userId)
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
    
    func cleanup() {
        loadTask?.cancel()
    }
    
    // MARK: - Private Methods
    private func resetPagination() {
        currentPage = 1
        hasMorePages = true
    }
    
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
            let response = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: wallType,
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
            let response = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: wallType,
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
