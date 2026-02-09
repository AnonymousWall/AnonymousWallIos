//
//  EditProfileNameViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for EditProfileNameView - handles profile name editing
//

import SwiftUI

@MainActor
class EditProfileNameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profileName = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    func loadCurrentProfileName(from user: User?) {
        if let currentUser = user {
            profileName = currentUser.profileName == "Anonymous" ? "" : currentUser.profileName
        }
    }
    
    func updateProfileName(authState: AuthState, onSuccess: @escaping () -> Void) {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        // Trim the profile name, empty string will be sent as-is (backend will set to Anonymous)
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let updatedUser = try await authService.updateProfileName(
                    profileName: trimmedName,
                    token: token,
                    userId: userId
                )
                
                // Update the user in auth state
                authState.updateUser(updatedUser)
                isSubmitting = false
                onSuccess()
            } catch {
                isSubmitting = false
                if let networkError = error as? NetworkError {
                    errorMessage = networkError.localizedDescription
                } else {
                    errorMessage = "Failed to update profile name: \(error.localizedDescription)"
                }
            }
        }
    }
}
