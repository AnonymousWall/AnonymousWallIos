//
//  InternshipDetailViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for InternshipDetailView - handles detail and comments logic
//

import SwiftUI

@MainActor
class InternshipDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var comments: [Comment] = []
    @Published var isLoadingComments = false
    @Published var isLoadingMoreComments = false
    @Published var commentText = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var commentToDelete: Comment?
    @Published var selectedSortOrder: SortOrder = .newest

    // MARK: - Dependencies
    private let service: InternshipServiceProtocol

    // MARK: - Private Properties
    private var pagination = Pagination()
    private var loadCommentsTask: Task<Void, Never>?

    // MARK: - Initialization
    init(service: InternshipServiceProtocol = InternshipService.shared) {
        self.service = service
    }

    // MARK: - Public Methods
    func loadComments(internshipId: String, authState: AuthState) {
        loadCommentsTask?.cancel()
        loadCommentsTask = Task {
            await performLoadComments(internshipId: internshipId, authState: authState)
        }
    }

    func refreshComments(internshipId: String, authState: AuthState) async {
        loadCommentsTask?.cancel()
        pagination.reset()
        loadCommentsTask = Task {
            await performLoadComments(internshipId: internshipId, authState: authState)
        }
        await loadCommentsTask?.value
    }

    func loadMoreCommentsIfNeeded(for comment: Comment, internshipId: String, authState: AuthState) {
        guard !isLoadingMoreComments && pagination.hasMorePages else { return }
        guard comment.id == comments.last?.id else { return }

        Task {
            guard !isLoadingMoreComments && pagination.hasMorePages else { return }
            isLoadingMoreComments = true
            await performLoadMoreComments(internshipId: internshipId, authState: authState)
        }
    }

    func sortOrderChanged(internshipId: String, authState: AuthState) {
        HapticFeedback.selection()
        loadCommentsTask?.cancel()
        comments = []
        pagination.reset()
        loadCommentsTask = Task {
            await performLoadComments(internshipId: internshipId, authState: authState)
        }
    }

    func submitComment(
        internshipId: String,
        authState: AuthState,
        internship: Binding<Internship>,
        onSuccess: @escaping () -> Void
    ) {
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
                _ = try await service.addComment(internshipId: internshipId, text: trimmedText, token: token, userId: userId)
                HapticFeedback.success()
                isSubmitting = false
                commentText = ""
                internship.wrappedValue = internship.wrappedValue.withUpdatedComments(comments: internship.wrappedValue.comments + 1)
                onSuccess()
                loadCommentsTask?.cancel()
                pagination.reset()
                loadCommentsTask = Task {
                    await performLoadComments(internshipId: internshipId, authState: authState)
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

    func deleteInternship(internship: Internship, authState: AuthState, onSuccess: @escaping () -> Void) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }

        Task {
            do {
                _ = try await service.hideInternship(internshipId: internship.id, token: token, userId: userId)
                HapticFeedback.success()
                onSuccess()
            } catch is CancellationError {
                return
            } catch NetworkError.cancelled {
                return
            } catch {
                errorMessage = "Failed to delete posting: \(error.localizedDescription)"
            }
        }
    }

    func deleteComment(_ comment: Comment, internshipId: String, authState: AuthState, internship: Binding<Internship>) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }

        Task {
            do {
                _ = try await service.hideComment(internshipId: internshipId, commentId: comment.id, token: token, userId: userId)
                HapticFeedback.success()
                internship.wrappedValue = internship.wrappedValue.withUpdatedComments(comments: max(0, internship.wrappedValue.comments - 1))
                loadCommentsTask?.cancel()
                pagination.reset()
                loadCommentsTask = Task {
                    await performLoadComments(internshipId: internshipId, authState: authState)
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

    // MARK: - Private Methods
    private func performLoadComments(internshipId: String, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }

        isLoadingComments = true
        errorMessage = nil

        defer { isLoadingComments = false }

        do {
            let response = try await service.getComments(
                internshipId: internshipId,
                token: token,
                userId: userId,
                page: pagination.currentPage,
                limit: 20,
                sort: selectedSortOrder
            )
            comments = response.data
            pagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performLoadMoreComments(internshipId: String, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMoreComments = false
            return
        }

        defer { isLoadingMoreComments = false }

        let nextPage = pagination.advanceToNextPage()

        do {
            let response = try await service.getComments(
                internshipId: internshipId,
                token: token,
                userId: userId,
                page: nextPage,
                limit: 20,
                sort: selectedSortOrder
            )
            comments.append(contentsOf: response.data)
            pagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
