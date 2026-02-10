//
//  CreatePostTabViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for CreatePostTabViewModel
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct CreatePostTabViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test func testViewModelInitializesWithFalseState() async throws {
        // Verify that CreatePostTabViewModel initializes with sheet dismissed
        let viewModel = CreatePostTabViewModel()
        
        // Verify initial state
        #expect(viewModel.showCreatePost == false)
    }
    
    // MARK: - Show Sheet Tests
    
    @Test func testShowCreatePostSheetSetsStateToTrue() async throws {
        // Setup
        let viewModel = CreatePostTabViewModel()
        
        // Verify initial state
        #expect(viewModel.showCreatePost == false)
        
        // Execute
        viewModel.showCreatePostSheet()
        
        // Verify
        #expect(viewModel.showCreatePost == true)
    }
    
    // MARK: - Dismiss Sheet Tests
    
    @Test func testDismissCreatePostSheetSetsStateToFalse() async throws {
        // Setup
        let viewModel = CreatePostTabViewModel()
        viewModel.showCreatePost = true // Set to true first
        
        // Verify initial state
        #expect(viewModel.showCreatePost == true)
        
        // Execute
        viewModel.dismissCreatePostSheet()
        
        // Verify
        #expect(viewModel.showCreatePost == false)
    }
    
    // MARK: - State Toggle Tests
    
    @Test func testSheetStateCanBeToggled() async throws {
        // Setup
        let viewModel = CreatePostTabViewModel()
        
        // Initial state
        #expect(viewModel.showCreatePost == false)
        
        // Show sheet
        viewModel.showCreatePostSheet()
        #expect(viewModel.showCreatePost == true)
        
        // Dismiss sheet
        viewModel.dismissCreatePostSheet()
        #expect(viewModel.showCreatePost == false)
        
        // Show again
        viewModel.showCreatePostSheet()
        #expect(viewModel.showCreatePost == true)
    }
}
