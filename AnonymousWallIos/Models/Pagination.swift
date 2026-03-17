//
//  Pagination.swift
//  AnonymousWallIos
//
//  Reusable pagination state abstraction
//

import Foundation

/// Encapsulates pagination state and logic in a thread-safe manner
struct Pagination {
    // MARK: - Properties
    private(set) var currentPage: Int
    private(set) var hasMorePages: Bool
    
    // MARK: - Initialization
    
    /// Initializes pagination with default values
    init() {
        self.currentPage = 1
        self.hasMorePages = true
    }
    
    // MARK: - Public Methods
    
    /// Resets pagination to initial state
    mutating func reset() {
        currentPage = 1
        hasMorePages = true
    }
    
    /// Updates pagination state based on total pages
    /// - Parameters:
    ///   - totalPages: Total number of pages available
    mutating func update(totalPages: Int) {
        hasMorePages = currentPage < totalPages
    }
    
    /// Returns the next page number without mutating state.
    /// Call commitNextPage() after a successful load.
    func nextPage() -> Int {
        return currentPage + 1
    }

    /// Commits the advance after a successful load.
    mutating func commitNextPage(totalPages: Int) {
        currentPage += 1
        hasMorePages = currentPage < totalPages
    }
}
