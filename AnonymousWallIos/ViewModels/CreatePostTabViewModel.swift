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
    @Published var showCreateInternship = false
    @Published var showCreateMarketplace = false

    // MARK: - Public Methods

    /// Show the create post sheet
    func showCreatePostSheet() {
        showCreatePost = true
    }

    /// Dismiss the create post sheet
    func dismissCreatePostSheet() {
        showCreatePost = false
    }

    /// Show the create internship sheet
    func showCreateInternshipSheet() {
        showCreateInternship = true
    }

    /// Dismiss the create internship sheet
    func dismissCreateInternshipSheet() {
        showCreateInternship = false
    }

    /// Show the create marketplace sheet
    func showCreateMarketplaceSheet() {
        showCreateMarketplace = true
    }

    /// Dismiss the create marketplace sheet
    func dismissCreateMarketplaceSheet() {
        showCreateMarketplace = false
    }
}

