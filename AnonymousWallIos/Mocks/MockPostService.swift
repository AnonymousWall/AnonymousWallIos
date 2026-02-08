//
//  MockPostService.swift
//  AnonymousWallIos
//
//  Mock implementation of PostServiceProtocol for unit testing
//  Provides configurable stub responses for success, failure, and empty states
//

import Foundation

/// Mock PostService for testing with configurable responses
public class MockPostService: PostServiceProtocol {
    
    // MARK: - Configuration
    
    /// Configuration for mock behavior
    public enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }
    
    /// Default error for failure scenarios
    public enum MockError: Error, LocalizedError {
        case postNotFound
        case unauthorized
        case networkError
        case serverError
        case invalidInput
        
        public var errorDescription: String? {
            switch self {
            case .postNotFound:
                return "Post not found"
            case .unauthorized:
                return "Unauthorized access"
            case .networkError:
                return "Network error"
            case .serverError:
                return "Server error"
            case .invalidInput:
                return "Invalid input"
            }
        }
    }
    
    // MARK: - State Tracking
    
    public var fetchPostsCalled = false
    public var getPostCalled = false
    public var createPostCalled = false
    public var toggleLikeCalled = false
    public var hidePostCalled = false
    public var unhidePostCalled = false
    public var addCommentCalled = false
    public var getCommentsCalled = false
    public var hideCommentCalled = false
    public var unhideCommentCalled = false
    public var getUserCommentsCalled = false
    public var getUserPostsCalled = false
    
    // MARK: - Configurable Behavior
    
    public var fetchPostsBehavior: MockBehavior = .success
    public var getPostBehavior: MockBehavior = .success
    public var createPostBehavior: MockBehavior = .success
    public var toggleLikeBehavior: MockBehavior = .success
    public var hidePostBehavior: MockBehavior = .success
    public var unhidePostBehavior: MockBehavior = .success
    public var addCommentBehavior: MockBehavior = .success
    public var getCommentsBehavior: MockBehavior = .success
    public var hideCommentBehavior: MockBehavior = .success
    public var unhideCommentBehavior: MockBehavior = .success
    public var getUserCommentsBehavior: MockBehavior = .success
    public var getUserPostsBehavior: MockBehavior = .success
    
    // MARK: - Configurable State
    
    public var mockPosts: [Post] = []
    public var mockComments: [Comment] = []
    public var mockPost: Post?
    public var mockComment: Comment?
    public var mockLikeResponse: LikeResponse?
    public var mockHideResponse: HidePostResponse?
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Post Operations
    
    public func fetchPosts(
        token: String,
        userId: String,
        wall: WallType,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> PostListResponse {
        fetchPostsCalled = true
        
        switch fetchPostsBehavior {
        case .success:
            return PostListResponse(
                data: mockPosts,
                pagination: PaginationInfo(
                    page: page,
                    limit: limit,
                    total: mockPosts.count,
                    totalPages: mockPosts.isEmpty ? 0 : (mockPosts.count + limit - 1) / limit
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return PostListResponse(
                data: [],
                pagination: PaginationInfo(page: page, limit: limit, total: 0, totalPages: 0)
            )
        }
    }
    
    public func getPost(
        postId: String,
        token: String,
        userId: String
    ) async throws -> Post {
        getPostCalled = true
        
        switch getPostBehavior {
        case .success:
            return mockPost ?? Post(
                id: postId,
                title: "Mock Post",
                content: "Mock content",
                wall: "CAMPUS",
                likes: 0,
                comments: 0,
                liked: false,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: true),
                createdAt: "2026-01-31T00:00:00Z",
                updatedAt: "2026-01-31T00:00:00Z"
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return Post(
                id: "",
                title: "",
                content: "",
                wall: "",
                likes: 0,
                comments: 0,
                liked: false,
                author: Post.Author(id: "", profileName: "", isAnonymous: false),
                createdAt: "",
                updatedAt: ""
            )
        }
    }
    
    public func createPost(
        title: String,
        content: String,
        wall: WallType,
        token: String,
        userId: String
    ) async throws -> Post {
        createPostCalled = true
        
        switch createPostBehavior {
        case .success:
            let newPost = Post(
                id: "new-post-\(mockPosts.count)",
                title: title,
                content: content,
                wall: wall.rawValue,
                likes: 0,
                comments: 0,
                liked: false,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: true),
                createdAt: "2026-01-31T00:00:00Z",
                updatedAt: "2026-01-31T00:00:00Z"
            )
            mockPosts.append(newPost)
            return newPost
        case .failure(let error):
            throw error
        case .emptyState:
            return Post(
                id: "",
                title: "",
                content: "",
                wall: "",
                likes: 0,
                comments: 0,
                liked: false,
                author: Post.Author(id: "", profileName: "", isAnonymous: false),
                createdAt: "",
                updatedAt: ""
            )
        }
    }
    
    public func toggleLike(
        postId: String,
        token: String,
        userId: String
    ) async throws -> LikeResponse {
        toggleLikeCalled = true
        
        switch toggleLikeBehavior {
        case .success:
            return mockLikeResponse ?? LikeResponse(liked: true, likeCount: 1)
        case .failure(let error):
            throw error
        case .emptyState:
            return LikeResponse(liked: false, likeCount: 0)
        }
    }
    
    public func hidePost(
        postId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        hidePostCalled = true
        
        switch hidePostBehavior {
        case .success:
            return mockHideResponse ?? HidePostResponse(message: "Post hidden successfully")
        case .failure(let error):
            throw error
        case .emptyState:
            return HidePostResponse(message: "")
        }
    }
    
    public func unhidePost(
        postId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        unhidePostCalled = true
        
        switch unhidePostBehavior {
        case .success:
            return mockHideResponse ?? HidePostResponse(message: "Post unhidden successfully")
        case .failure(let error):
            throw error
        case .emptyState:
            return HidePostResponse(message: "")
        }
    }
    
    // MARK: - Comment Operations
    
    public func addComment(
        postId: String,
        text: String,
        token: String,
        userId: String
    ) async throws -> Comment {
        addCommentCalled = true
        
        switch addCommentBehavior {
        case .success:
            let newComment = Comment(
                id: "new-comment-\(mockComments.count)",
                postId: postId,
                text: text,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: true),
                createdAt: "2026-01-31T00:00:00Z"
            )
            mockComments.append(newComment)
            return newComment
        case .failure(let error):
            throw error
        case .emptyState:
            return Comment(
                id: "",
                postId: "",
                text: "",
                author: Post.Author(id: "", profileName: "", isAnonymous: false),
                createdAt: ""
            )
        }
    }
    
    public func getComments(
        postId: String,
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse {
        getCommentsCalled = true
        
        switch getCommentsBehavior {
        case .success:
            let postComments = mockComments.filter { $0.postId == postId }
            return CommentListResponse(
                data: postComments,
                pagination: PaginationInfo(
                    page: page,
                    limit: limit,
                    total: postComments.count,
                    totalPages: postComments.isEmpty ? 0 : (postComments.count + limit - 1) / limit
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return CommentListResponse(
                data: [],
                pagination: PaginationInfo(page: page, limit: limit, total: 0, totalPages: 0)
            )
        }
    }
    
    public func hideComment(
        postId: String,
        commentId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        hideCommentCalled = true
        
        switch hideCommentBehavior {
        case .success:
            return mockHideResponse ?? HidePostResponse(message: "Comment hidden successfully")
        case .failure(let error):
            throw error
        case .emptyState:
            return HidePostResponse(message: "")
        }
    }
    
    public func unhideComment(
        postId: String,
        commentId: String,
        token: String,
        userId: String
    ) async throws -> HidePostResponse {
        unhideCommentCalled = true
        
        switch unhideCommentBehavior {
        case .success:
            return mockHideResponse ?? HidePostResponse(message: "Comment unhidden successfully")
        case .failure(let error):
            throw error
        case .emptyState:
            return HidePostResponse(message: "")
        }
    }
    
    // MARK: - User Operations
    
    public func getUserComments(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse {
        getUserCommentsCalled = true
        
        switch getUserCommentsBehavior {
        case .success:
            return CommentListResponse(
                data: mockComments,
                pagination: PaginationInfo(
                    page: page,
                    limit: limit,
                    total: mockComments.count,
                    totalPages: mockComments.isEmpty ? 0 : (mockComments.count + limit - 1) / limit
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return CommentListResponse(
                data: [],
                pagination: PaginationInfo(page: page, limit: limit, total: 0, totalPages: 0)
            )
        }
    }
    
    public func getUserPosts(
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> PostListResponse {
        getUserPostsCalled = true
        
        switch getUserPostsBehavior {
        case .success:
            return PostListResponse(
                data: mockPosts,
                pagination: PaginationInfo(
                    page: page,
                    limit: limit,
                    total: mockPosts.count,
                    totalPages: mockPosts.isEmpty ? 0 : (mockPosts.count + limit - 1) / limit
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return PostListResponse(
                data: [],
                pagination: PaginationInfo(page: page, limit: limit, total: 0, totalPages: 0)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset all call tracking flags
    public func resetCallTracking() {
        fetchPostsCalled = false
        getPostCalled = false
        createPostCalled = false
        toggleLikeCalled = false
        hidePostCalled = false
        unhidePostCalled = false
        addCommentCalled = false
        getCommentsCalled = false
        hideCommentCalled = false
        unhideCommentCalled = false
        getUserCommentsCalled = false
        getUserPostsCalled = false
    }
    
    /// Reset all behaviors to success
    public func resetBehaviors() {
        fetchPostsBehavior = .success
        getPostBehavior = .success
        createPostBehavior = .success
        toggleLikeBehavior = .success
        hidePostBehavior = .success
        unhidePostBehavior = .success
        addCommentBehavior = .success
        getCommentsBehavior = .success
        hideCommentBehavior = .success
        unhideCommentBehavior = .success
        getUserCommentsBehavior = .success
        getUserPostsBehavior = .success
    }
    
    /// Configure all methods to fail with specific error
    public func configureAllToFail(with error: Error) {
        fetchPostsBehavior = .failure(error)
        getPostBehavior = .failure(error)
        createPostBehavior = .failure(error)
        toggleLikeBehavior = .failure(error)
        hidePostBehavior = .failure(error)
        unhidePostBehavior = .failure(error)
        addCommentBehavior = .failure(error)
        getCommentsBehavior = .failure(error)
        hideCommentBehavior = .failure(error)
        unhideCommentBehavior = .failure(error)
        getUserCommentsBehavior = .failure(error)
        getUserPostsBehavior = .failure(error)
    }
    
    /// Configure all methods to return empty state
    public func configureAllToEmptyState() {
        fetchPostsBehavior = .emptyState
        getPostBehavior = .emptyState
        createPostBehavior = .emptyState
        toggleLikeBehavior = .emptyState
        hidePostBehavior = .emptyState
        unhidePostBehavior = .emptyState
        addCommentBehavior = .emptyState
        getCommentsBehavior = .emptyState
        hideCommentBehavior = .emptyState
        unhideCommentBehavior = .emptyState
        getUserCommentsBehavior = .emptyState
        getUserPostsBehavior = .emptyState
    }
    
    /// Clear all stored mock data
    public func clearMockData() {
        mockPosts.removeAll()
        mockComments.removeAll()
        mockPost = nil
        mockComment = nil
        mockLikeResponse = nil
        mockHideResponse = nil
    }
}
