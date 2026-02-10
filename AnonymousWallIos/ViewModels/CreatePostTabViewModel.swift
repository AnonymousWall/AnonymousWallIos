//
//  CreatePostTabViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for CreatePostTabView - handles sheet presentation state
//

import SwiftUI

@MainActor
class CreatePostTabViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showCreatePost = false
    
    // MARK: - Public Methods
    
    /// Show the create post sheet
    func showCreatePostSheet() {
        showCreatePost = true
    }
    
    /// Dismiss the create post sheet
    func dismissCreatePostSheet() {
        showCreatePost = false
    }
}
