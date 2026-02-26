//
//  MarketplaceFeedViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for marketplace feed views (campus and national walls)
//

import SwiftUI

@MainActor
class MarketplaceFeedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var items: [MarketplaceItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var selectedSortOrder: MarketplaceSortOrder = .newest

    // MARK: - Private Properties
    private var pagination = Pagination()
    private var loadTask: Task<Void, Never>?
    private let wallType: WallType
    private let service: MarketplaceServiceProtocol

    // MARK: - Initialization
    init(wallType: WallType, service: MarketplaceServiceProtocol = MarketplaceService.shared) {
        self.wallType = wallType
        self.service = service
    }

    // MARK: - Public Methods
    func loadItems(authState: AuthState) {
        loadTask?.cancel()
        loadTask = Task {
            await performLoad(authState: authState)
        }
    }

    func refreshItems(authState: AuthState) async {
        loadTask?.cancel()
        pagination.reset()
        loadTask = Task {
            await performLoad(authState: authState)
        }
        await loadTask?.value
    }

    func loadMoreIfNeeded(for item: MarketplaceItem, authState: AuthState) {
        guard !isLoadingMore && pagination.hasMorePages else { return }
        guard item.id == items.last?.id else { return }

        Task {
            guard !isLoadingMore && pagination.hasMorePages else { return }
            isLoadingMore = true
            await performLoadMore(authState: authState)
        }
    }

    func sortOrderChanged(authState: AuthState) {
        HapticFeedback.selection()
        loadTask?.cancel()
        items = []
        pagination.reset()
        loadTask = Task {
            await performLoad(authState: authState)
        }
    }

    func deleteItem(_ item: MarketplaceItem, authState: AuthState) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required to delete item."
            return
        }

        Task {
            do {
                _ = try await service.hideItem(itemId: item.id, token: token, userId: userId)
                pagination.reset()
                await performLoad(authState: authState)
            } catch {
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .unauthorized:
                        errorMessage = "Session expired. Please log in again."
                    case .forbidden:
                        errorMessage = "You don't have permission to delete this item."
                    case .notFound:
                        errorMessage = "Item not found."
                    case .noConnection:
                        errorMessage = "No internet connection. Please check your network."
                    default:
                        errorMessage = "Failed to delete item. Please try again."
                    }
                } else {
                    errorMessage = "Failed to delete item. Please try again."
                }
            }
        }
    }

    func cleanup() {
        loadTask?.cancel()
    }

    // MARK: - Private Methods
    private func performLoad(authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let response = try await service.fetchItems(
                token: token,
                userId: userId,
                wall: wallType,
                page: pagination.currentPage,
                limit: 20,
                sortBy: selectedSortOrder
            )
            items = response.data
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
            let response = try await service.fetchItems(
                token: token,
                userId: userId,
                wall: wallType,
                page: nextPage,
                limit: 20,
                sortBy: selectedSortOrder
            )
            items.append(contentsOf: response.data)
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
