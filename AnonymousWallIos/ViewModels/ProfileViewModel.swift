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
    @Published var myInternships: [Internship] = []
    @Published var myMarketplaceItems: [MarketplaceItem] = []
    @Published var commentParentMap: [String: CommentParent] = [:]  // ✅ Changed from commentPostMap
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var postSortOrder: SortOrder = .newest
    @Published var commentSortOrder: SortOrder = .newest
    @Published var internshipSortOrder: SortOrder = .newest
    @Published var marketplaceSortOrder: SortOrder = .newest
    
    // MARK: - Pagination State
    private var postsPagination = Pagination()
    private var commentsPagination = Pagination()
    private var internshipsPagination = Pagination()
    private var marketplacesPagination = Pagination()
    
    @Published var isLoadingMorePosts = false
    @Published var isLoadingMoreComments = false
    @Published var isLoadingMoreInternships = false
    @Published var isLoadingMoreMarketplaceItems = false
    
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
            switch selectedSegment {
            case 0: await loadPosts(authState: authState)
            case 1: await loadComments(authState: authState)
            case 2: await loadInternships(authState: authState)
            case 3: await loadMarketplaceItems(authState: authState)
            default: break
            }
        }
    }
    
    func refreshContent(authState: AuthState) async {
        loadTask?.cancel()
        
        switch selectedSegment {
        case 0:
            postsPagination.reset()
            await loadPosts(authState: authState)
        case 1:
            commentsPagination.reset()
            await loadComments(authState: authState)
        case 2:
            internshipsPagination.reset()
            await loadInternships(authState: authState)
        case 3:
            marketplacesPagination.reset()
            await loadMarketplaceItems(authState: authState)
        default:
            break
        }
    }
    
    func segmentChanged(authState: AuthState) {
        HapticFeedback.selection()
        loadTask?.cancel()
        loadTask = Task {
            switch selectedSegment {
            case 0:
                if myPosts.isEmpty { await loadPosts(authState: authState) }
            case 1:
                if myComments.isEmpty { await loadComments(authState: authState) }
            case 2:
                if myInternships.isEmpty { await loadInternships(authState: authState) }
            case 3:
                if myMarketplaceItems.isEmpty { await loadMarketplaceItems(authState: authState) }
            default:
                break
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
    
    func internshipSortChanged(authState: AuthState) {
        HapticFeedback.selection()
        myInternships = []
        internshipsPagination.reset()
        loadTask?.cancel()
        loadTask = Task {
            await loadInternships(authState: authState)
        }
    }
    
    func marketplaceSortChanged(authState: AuthState) {
        HapticFeedback.selection()
        myMarketplaceItems = []
        marketplacesPagination.reset()
        loadTask?.cancel()
        loadTask = Task {
            await loadMarketplaceItems(authState: authState)
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
    
    func loadMoreInternshipsIfNeeded(for internship: Internship, authState: AuthState) {
        guard !isLoadingMoreInternships && internshipsPagination.hasMorePages else { return }
        guard internship.id == myInternships.last?.id else { return }
        
        Task {
            guard !isLoadingMoreInternships && internshipsPagination.hasMorePages else { return }
            isLoadingMoreInternships = true
            await performLoadMoreInternships(authState: authState)
        }
    }
    
    func loadMoreMarketplaceItemsIfNeeded(for item: MarketplaceItem, authState: AuthState) {
        guard !isLoadingMoreMarketplaceItems && marketplacesPagination.hasMorePages else { return }
        guard item.id == myMarketplaceItems.last?.id else { return }
        
        Task {
            guard !isLoadingMoreMarketplaceItems && marketplacesPagination.hasMorePages else { return }
            isLoadingMoreMarketplaceItems = true
            await performLoadMoreMarketplaceItems(authState: authState)
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
    
    func deleteInternship(_ internship: Internship, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                _ = try await internshipService.hideInternship(internshipId: internship.id, token: token, userId: userId)
                internshipsPagination.reset()
                await loadInternships(authState: authState)
            } catch {
                errorMessage = "Failed to delete internship: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteMarketplaceItem(_ item: MarketplaceItem, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            return
        }
        
        Task {
            do {
                _ = try await marketplaceService.hideItem(itemId: item.id, token: token, userId: userId)
                marketplacesPagination.reset()
                await loadMarketplaceItems(authState: authState)
            } catch {
                errorMessage = "Failed to delete listing: \(error.localizedDescription)"
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
    
    private func loadInternships(authState: AuthState) async {
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
            let response = try await userService.getUserInternships(
                token: token,
                userId: userId,
                page: internshipsPagination.currentPage,
                limit: 20,
                sort: internshipSortOrder
            )
            myInternships = response.data
            internshipsPagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func performLoadMoreInternships(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMoreInternships = false
            return
        }
        
        defer {
            isLoadingMoreInternships = false
        }
        
        let nextPage = internshipsPagination.advanceToNextPage()
        
        do {
            let response = try await userService.getUserInternships(
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: internshipSortOrder
            )
            myInternships.append(contentsOf: response.data)
            internshipsPagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadMarketplaceItems(authState: AuthState) async {
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
            let response = try await userService.getUserMarketplaces(
                token: token,
                userId: userId,
                page: marketplacesPagination.currentPage,
                limit: 20,
                sort: marketplaceSortOrder
            )
            myMarketplaceItems = response.data
            marketplacesPagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func performLoadMoreMarketplaceItems(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMoreMarketplaceItems = false
            return
        }
        
        defer {
            isLoadingMoreMarketplaceItems = false
        }
        
        let nextPage = marketplacesPagination.advanceToNextPage()
        
        do {
            let response = try await userService.getUserMarketplaces(
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: marketplaceSortOrder
            )
            myMarketplaceItems.append(contentsOf: response.data)
            marketplacesPagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
