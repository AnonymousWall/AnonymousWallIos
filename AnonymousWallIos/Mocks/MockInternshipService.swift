//
//  MockInternshipService.swift
//  AnonymousWallIos
//
//  Mock implementation of InternshipServiceProtocol for unit testing
//

import Foundation

class MockInternshipService: InternshipServiceProtocol {

    // MARK: - Configuration

    enum MockBehavior {
        case success
        case failure(Error)
        case emptyState
    }

    // MARK: - State Tracking

    var fetchInternshipsCalled = false
    var getInternshipCalled = false
    var createInternshipCalled = false
    var hideInternshipCalled = false
    var unhideInternshipCalled = false
    var addCommentCalled = false
    var getCommentsCalled = false
    var hideCommentCalled = false
    var unhideCommentCalled = false

    // MARK: - Configurable Behavior

    var fetchInternshipsBehavior: MockBehavior = .success
    var getInternshipBehavior: MockBehavior = .success
    var createInternshipBehavior: MockBehavior = .success
    var hideInternshipBehavior: MockBehavior = .success
    var unhideInternshipBehavior: MockBehavior = .success
    var addCommentBehavior: MockBehavior = .success
    var getCommentsBehavior: MockBehavior = .success
    var hideCommentBehavior: MockBehavior = .success
    var unhideCommentBehavior: MockBehavior = .success

    // MARK: - Mock Data

    var mockInternships: [Internship] = []
    var mockInternship: Internship?
    var mockComments: [Comment] = []
    var mockHideResponse: HidePostResponse?

    // MARK: - Initialization

    init() {}

    // MARK: - Internship Operations

    func fetchInternships(
        token: String,
        userId: String,
        wall: WallType,
        page: Int,
        limit: Int,
        sortBy: FeedSortOrder
    ) async throws -> InternshipListResponse {
        fetchInternshipsCalled = true
        switch fetchInternshipsBehavior {
        case .success:
            return InternshipListResponse(
                data: mockInternships,
                pagination: PostListResponse.Pagination(
                    page: page,
                    limit: limit,
                    total: mockInternships.count,
                    totalPages: mockInternships.isEmpty ? 0 : (mockInternships.count + limit - 1) / limit
                )
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return InternshipListResponse(
                data: [],
                pagination: PostListResponse.Pagination(page: page, limit: limit, total: 0, totalPages: 0)
            )
        }
    }

    func getInternship(
        internshipId: String,
        token: String,
        userId: String
    ) async throws -> Internship {
        getInternshipCalled = true
        switch getInternshipBehavior {
        case .success:
            return mockInternship ?? Internship(
                id: internshipId,
                company: "Mock Company",
                role: "Mock Role",
                salary: nil,
                location: nil,
                description: nil,
                deadline: nil,
                wall: "CAMPUS",
                comments: 0,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: false),
                createdAt: "2026-02-19T00:00:00Z",
                updatedAt: "2026-02-19T00:00:00Z"
            )
        case .failure(let error):
            throw error
        case .emptyState:
            return Internship(
                id: "", company: "", role: "", salary: nil, location: nil, description: nil,
                deadline: nil, wall: "", comments: 0,
                author: Post.Author(id: "", profileName: "", isAnonymous: false),
                createdAt: "", updatedAt: ""
            )
        }
    }

    func createInternship(
        company: String,
        role: String,
        salary: String?,
        location: String?,
        description: String?,
        deadline: String?,
        wall: WallType,
        token: String,
        userId: String
    ) async throws -> Internship {
        createInternshipCalled = true
        switch createInternshipBehavior {
        case .success:
            let item = Internship(
                id: "new-internship-\(mockInternships.count)",
                company: company,
                role: role,
                salary: salary,
                location: location,
                description: description,
                deadline: deadline,
                wall: wall.rawValue,
                comments: 0,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: false),
                createdAt: "2026-02-19T00:00:00Z",
                updatedAt: "2026-02-19T00:00:00Z"
            )
            mockInternships.append(item)
            return item
        case .failure(let error):
            throw error
        case .emptyState:
            return Internship(
                id: "", company: "", role: "", salary: nil, location: nil, description: nil,
                deadline: nil, wall: "", comments: 0,
                author: Post.Author(id: "", profileName: "", isAnonymous: false),
                createdAt: "", updatedAt: ""
            )
        }
    }

    func hideInternship(internshipId: String, token: String, userId: String) async throws -> HidePostResponse {
        hideInternshipCalled = true
        switch hideInternshipBehavior {
        case .success: return mockHideResponse ?? HidePostResponse(message: "Internship posting hidden successfully")
        case .failure(let error): throw error
        case .emptyState: return HidePostResponse(message: "")
        }
    }

    func unhideInternship(internshipId: String, token: String, userId: String) async throws -> HidePostResponse {
        unhideInternshipCalled = true
        switch unhideInternshipBehavior {
        case .success: return mockHideResponse ?? HidePostResponse(message: "Internship posting unhidden successfully")
        case .failure(let error): throw error
        case .emptyState: return HidePostResponse(message: "")
        }
    }

    // MARK: - Comment Operations

    func addComment(internshipId: String, text: String, token: String, userId: String) async throws -> Comment {
        addCommentCalled = true
        switch addCommentBehavior {
        case .success:
            let comment = Comment(
                id: "new-comment-\(mockComments.count)",
                postId: internshipId,
                parentType: "INTERNSHIP",
                text: text,
                author: Post.Author(id: userId, profileName: "Mock User", isAnonymous: true),
                createdAt: "2026-02-19T00:00:00Z"
            )
            mockComments.append(comment)
            return comment
        case .failure(let error): throw error
        case .emptyState:
            return Comment(id: "", postId: "", parentType: nil, text: "", author: Post.Author(id: "", profileName: "", isAnonymous: false), createdAt: "")
        }
    }

    func getComments(
        internshipId: String,
        token: String,
        userId: String,
        page: Int,
        limit: Int,
        sort: SortOrder
    ) async throws -> CommentListResponse {
        getCommentsCalled = true
        switch getCommentsBehavior {
        case .success:
            let filtered = mockComments.filter { $0.postId == internshipId }
            return CommentListResponse(
                data: filtered,
                pagination: PostListResponse.Pagination(
                    page: page, limit: limit, total: filtered.count,
                    totalPages: filtered.isEmpty ? 0 : (filtered.count + limit - 1) / limit
                )
            )
        case .failure(let error): throw error
        case .emptyState:
            return CommentListResponse(data: [], pagination: PostListResponse.Pagination(page: page, limit: limit, total: 0, totalPages: 0))
        }
    }

    func hideComment(internshipId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        hideCommentCalled = true
        switch hideCommentBehavior {
        case .success: return mockHideResponse ?? HidePostResponse(message: "Comment hidden successfully")
        case .failure(let error): throw error
        case .emptyState: return HidePostResponse(message: "")
        }
    }

    func unhideComment(internshipId: String, commentId: String, token: String, userId: String) async throws -> HidePostResponse {
        unhideCommentCalled = true
        switch unhideCommentBehavior {
        case .success: return mockHideResponse ?? HidePostResponse(message: "Comment unhidden successfully")
        case .failure(let error): throw error
        case .emptyState: return HidePostResponse(message: "")
        }
    }

    // MARK: - Helper Methods

    func resetCallTracking() {
        fetchInternshipsCalled = false
        getInternshipCalled = false
        createInternshipCalled = false
        hideInternshipCalled = false
        unhideInternshipCalled = false
        addCommentCalled = false
        getCommentsCalled = false
        hideCommentCalled = false
        unhideCommentCalled = false
    }
}
