//
//  PaginationTests.swift
//  AnonymousWallIosTests
//
//  Comprehensive tests for Pagination model
//

import Testing
@testable import AnonymousWallIos

struct PaginationTests {
    
    // MARK: - Initialization Tests
    
    @Test func testInitialState() {
        let pagination = Pagination()
        
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
    }
    
    // MARK: - Reset Behavior Tests
    
    @Test func testResetToInitialState() {
        var pagination = Pagination()
        
        // Advance pages and update state
        _ = pagination.advanceToNextPage()
        _ = pagination.advanceToNextPage()
        pagination.update(totalPages: 2)
        
        #expect(pagination.currentPage == 3)
        #expect(pagination.hasMorePages == false)
        
        // Reset
        pagination.reset()
        
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
    }
    
    @Test func testResetMultipleTimes() {
        var pagination = Pagination()
        
        // Reset multiple times
        pagination.reset()
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
        
        pagination.reset()
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
    }
    
    @Test func testResetAfterVariousStates() {
        var pagination = Pagination()
        
        // State 1: On page 5
        for _ in 0..<4 {
            _ = pagination.advanceToNextPage()
        }
        #expect(pagination.currentPage == 5)
        
        pagination.reset()
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
        
        // State 2: No more pages
        pagination.update(totalPages: 1)
        #expect(pagination.hasMorePages == false)
        
        pagination.reset()
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
    }
    
    // MARK: - Last Page Logic Tests
    
    @Test func testLastPageDetection() {
        var pagination = Pagination()
        
        // Simulate reaching last page
        pagination.update(totalPages: 1)
        
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == false)
    }
    
    @Test func testNotLastPage() {
        var pagination = Pagination()
        
        // Current page is less than total pages
        pagination.update(totalPages: 5)
        
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
    }
    
    @Test func testLastPageAfterAdvance() {
        var pagination = Pagination()
        
        // Advance to page 2
        _ = pagination.advanceToNextPage()
        #expect(pagination.currentPage == 2)
        
        // Update with totalPages = 2 (we're on the last page)
        pagination.update(totalPages: 2)
        #expect(pagination.hasMorePages == false)
    }
    
    @Test func testHasMorePagesAfterAdvance() {
        var pagination = Pagination()
        
        // Advance to page 2
        _ = pagination.advanceToNextPage()
        #expect(pagination.currentPage == 2)
        
        // Update with totalPages = 5 (more pages available)
        pagination.update(totalPages: 5)
        #expect(pagination.hasMorePages == true)
    }
    
    @Test func testMultiplePageAdvancesBeforeLastPage() {
        var pagination = Pagination()
        
        // Advance to page 3
        _ = pagination.advanceToNextPage() // page 2
        _ = pagination.advanceToNextPage() // page 3
        #expect(pagination.currentPage == 3)
        
        // Total pages is 5 - still has more
        pagination.update(totalPages: 5)
        #expect(pagination.hasMorePages == true)
        
        // Advance to page 5 (last page)
        _ = pagination.advanceToNextPage() // page 4
        _ = pagination.advanceToNextPage() // page 5
        #expect(pagination.currentPage == 5)
        
        pagination.update(totalPages: 5)
        #expect(pagination.hasMorePages == false)
    }
    
    // MARK: - Empty Response Handling Tests
    
    @Test func testEmptyResponseNoPages() {
        var pagination = Pagination()
        
        // Empty response: totalPages = 0
        pagination.update(totalPages: 0)
        
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == false)
    }
    
    @Test func testEmptyResponseAfterAdvance() {
        var pagination = Pagination()
        
        // Advance to page 2
        _ = pagination.advanceToNextPage()
        #expect(pagination.currentPage == 2)
        
        // Empty response
        pagination.update(totalPages: 0)
        #expect(pagination.hasMorePages == false)
    }
    
    @Test func testZeroTotalPagesScenario() {
        var pagination = Pagination()
        
        // Simulate empty result set from API
        pagination.update(totalPages: 0)
        
        #expect(pagination.hasMorePages == false)
    }
    
    // MARK: - Page Advancement Tests
    
    @Test func testAdvanceToNextPage() {
        var pagination = Pagination()
        
        let nextPage = pagination.advanceToNextPage()
        
        #expect(nextPage == 2)
        #expect(pagination.currentPage == 2)
    }
    
    @Test func testMultiplePageAdvancements() {
        var pagination = Pagination()
        
        let page2 = pagination.advanceToNextPage()
        #expect(page2 == 2)
        #expect(pagination.currentPage == 2)
        
        let page3 = pagination.advanceToNextPage()
        #expect(page3 == 3)
        #expect(pagination.currentPage == 3)
        
        let page4 = pagination.advanceToNextPage()
        #expect(page4 == 4)
        #expect(pagination.currentPage == 4)
    }
    
    @Test func testAdvanceReturnsCorrectPageNumber() {
        var pagination = Pagination()
        
        // Advance 10 times
        for expectedPage in 2...11 {
            let returnedPage = pagination.advanceToNextPage()
            #expect(returnedPage == expectedPage)
            #expect(pagination.currentPage == expectedPage)
        }
    }
    
    // MARK: - Update Behavior Tests
    
    @Test func testUpdateDoesNotChangeCurrentPage() {
        var pagination = Pagination()
        
        // Advance to page 3
        _ = pagination.advanceToNextPage()
        _ = pagination.advanceToNextPage()
        #expect(pagination.currentPage == 3)
        
        // Update should not change current page
        pagination.update(totalPages: 10)
        #expect(pagination.currentPage == 3)
    }
    
    @Test func testUpdateOnlyChangesHasMorePages() {
        var pagination = Pagination()
        
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
        
        // Update to last page
        pagination.update(totalPages: 1)
        #expect(pagination.currentPage == 1) // unchanged
        #expect(pagination.hasMorePages == false) // changed
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func testAdvanceBeyondTotalPages() {
        var pagination = Pagination()
        
        // Set total pages to 2
        pagination.update(totalPages: 2)
        #expect(pagination.hasMorePages == true)
        
        // Advance to page 2
        _ = pagination.advanceToNextPage()
        pagination.update(totalPages: 2)
        #expect(pagination.hasMorePages == false)
        
        // Advancing beyond total pages is allowed
        // (API will return empty data)
        let page3 = pagination.advanceToNextPage()
        #expect(page3 == 3)
        #expect(pagination.currentPage == 3)
    }
    
    @Test func testNegativeTotalPages() {
        var pagination = Pagination()
        
        // Negative total pages should result in no more pages
        pagination.update(totalPages: -1)
        
        #expect(pagination.hasMorePages == false)
    }
    
    @Test func testVeryLargeTotalPages() {
        var pagination = Pagination()
        
        // Test with very large number
        pagination.update(totalPages: 999999)
        
        #expect(pagination.hasMorePages == true)
        
        // Even at page 1000, should still have more
        for _ in 0..<999 {
            _ = pagination.advanceToNextPage()
        }
        #expect(pagination.currentPage == 1000)
        
        pagination.update(totalPages: 999999)
        #expect(pagination.hasMorePages == true)
    }
    
    // MARK: - Typical Usage Patterns Tests
    
    @Test func testTypicalPaginationFlow() {
        var pagination = Pagination()
        
        // Load page 1
        #expect(pagination.currentPage == 1)
        pagination.update(totalPages: 5)
        #expect(pagination.hasMorePages == true)
        
        // Load page 2
        _ = pagination.advanceToNextPage()
        #expect(pagination.currentPage == 2)
        pagination.update(totalPages: 5)
        #expect(pagination.hasMorePages == true)
        
        // Load page 3
        _ = pagination.advanceToNextPage()
        #expect(pagination.currentPage == 3)
        pagination.update(totalPages: 5)
        #expect(pagination.hasMorePages == true)
        
        // Refresh (reset)
        pagination.reset()
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
    }
    
    @Test func testPaginationWithFilterChange() {
        var pagination = Pagination()
        
        // Load some pages
        _ = pagination.advanceToNextPage() // page 2
        _ = pagination.advanceToNextPage() // page 3
        pagination.update(totalPages: 10)
        
        #expect(pagination.currentPage == 3)
        #expect(pagination.hasMorePages == true)
        
        // User changes filter - reset pagination
        pagination.reset()
        
        #expect(pagination.currentPage == 1)
        #expect(pagination.hasMorePages == true)
    }
    
    @Test func testPaginationReachingEnd() {
        var pagination = Pagination()
        
        // Simulate loading until end
        pagination.update(totalPages: 3)
        #expect(pagination.hasMorePages == true)
        
        _ = pagination.advanceToNextPage() // page 2
        pagination.update(totalPages: 3)
        #expect(pagination.hasMorePages == true)
        
        _ = pagination.advanceToNextPage() // page 3
        pagination.update(totalPages: 3)
        #expect(pagination.hasMorePages == false) // reached end
    }
}
