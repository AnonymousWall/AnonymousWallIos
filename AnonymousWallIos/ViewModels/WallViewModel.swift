//
//  WallViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for WallView - handles post feed business logic
//

import SwiftUI

@MainActor
class WallViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var posts: [Post] = []
    @Published var isLoadingPosts = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var pagination = Pagination()
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Public Methods
    func loadPosts(authState: AuthState) {
        loadTask?.cancel()
        loadTask = Task {
            await performLoadPosts(authState: authState)
        }
    }
    
    func refreshPosts(authState: AuthState) async {
        loadTask?.cancel()
        pagination.reset()
        loadTask = Task {
            await performLoadPosts(authState: authState)
        }
        await loadTask?.value
    }
    
    func loadMoreIfNeeded(for post: Post, authState: AuthState) {
        guard !isLoadingMore && pagination.hasMorePages else { return }
        guard post.id == posts.last?.id else { return }
        
        Task {
            guard !isLoadingMore && pagination.hasMorePages else { return }
            isLoadingMore = true
            await performLoadMorePosts(authState: authState)
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
                pagination.reset()
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
                wall: .campus,
                page: pagination.currentPage,
                limit: 20,
                sort: .newest
            )
            posts = response.data
            pagination.updateAfterLoad(totalPages: response.pagination.totalPages)
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
        
        let nextPage = pagination.advanceToNextPage()
        
        do {
            let response = try await PostService.shared.fetchPosts(
                token: token,
                userId: userId,
                wall: .campus,
                page: nextPage,
                limit: 20,
                sort: .newest
            )
            
            posts.append(contentsOf: response.data)
            pagination.updateAfterLoadingMore(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
