//
//  InternshipFeedViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for internship feed views (campus and national walls)
//

import SwiftUI

@MainActor
class InternshipFeedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var internships: [Internship] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedSortOrder: SortOrder = .newest

    // MARK: - Private Properties
    private var pagination = Pagination()
    private var loadTask: Task<Void, Never>?
    private let wallType: WallType
    private let service: InternshipServiceProtocol

    // MARK: - Initialization
    init(wallType: WallType, service: InternshipServiceProtocol = InternshipService.shared) {
        self.wallType = wallType
        self.service = service
    }

    // MARK: - Public Methods
    func loadInternships(authState: AuthState) {
        loadTask?.cancel()
        loadTask = Task {
            await performLoad(authState: authState)
        }
    }

    func refreshInternships(authState: AuthState) async {
        loadTask?.cancel()
        pagination.reset()
        loadTask = Task {
            await performLoad(authState: authState)
        }
        await loadTask?.value
    }

    func loadMoreIfNeeded(for internship: Internship, authState: AuthState) {
        guard !isLoadingMore && pagination.hasMorePages else { return }
        guard internship.id == internships.last?.id else { return }

        Task {
            guard !isLoadingMore && pagination.hasMorePages else { return }
            isLoadingMore = true
            await performLoadMore(authState: authState)
        }
    }

    func sortOrderChanged(authState: AuthState) {
        HapticFeedback.selection()
        loadTask?.cancel()
        internships = []
        pagination.reset()
        loadTask = Task {
            await performLoad(authState: authState)
        }
    }

    func deleteInternship(_ internship: Internship, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to delete internship."
            return
        }

        Task {
            do {
                _ = try await service.hideInternship(internshipId: internship.id, token: token, userId: userId)
                pagination.reset()
                await performLoad(authState: authState)
            } catch {
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .unauthorized:
                        errorMessage = "Session expired. Please log in again."
                    case .forbidden:
                        errorMessage = "You don't have permission to delete this posting."
                    case .notFound:
                        errorMessage = "Internship posting not found."
                    case .noConnection:
                        errorMessage = "No internet connection. Please check your network."
                    default:
                        errorMessage = "Failed to delete posting. Please try again."
                    }
                } else {
                    errorMessage = "Failed to delete posting. Please try again."
                }
            }
        }
    }

    func cleanup() {
        loadTask?.cancel()
    }

    /// Removes all internships authored by the given userId (called after blocking a user).
    func removeInternshipsFromUser(_ userId: String) {
        internships.removeAll { $0.author.id == userId }
    }

    // MARK: - Private Methods
    private func performLoad(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await service.fetchInternships(
                token: token,
                userId: userId,
                wall: wallType,
                page: pagination.currentPage,
                limit: 20,
                sortBy: selectedSortOrder
            )
            internships = response.data
            pagination.update(totalPages: response.pagination.totalPages)
        } catch is CancellationError {
            return
        } catch NetworkError.cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performLoadMore(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            isLoadingMore = false
            return
        }

        defer { isLoadingMore = false }

        let nextPage = pagination.advanceToNextPage()

        do {
            let response = try await service.fetchInternships(
                token: token,
                userId: userId,
                wall: wallType,
                page: nextPage,
                limit: 20,
                sortBy: selectedSortOrder
            )
            internships.append(contentsOf: response.data)
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
