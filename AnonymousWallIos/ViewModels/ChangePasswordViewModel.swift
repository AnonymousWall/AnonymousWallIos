//
//  ChangePasswordViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for ChangePasswordView - handles password change
//

import SwiftUI

@MainActor
class ChangePasswordViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var oldPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    // MARK: - Computed Properties
    var isButtonDisabled: Bool {
        oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading
    }
    
    // MARK: - Public Methods
    func changePassword(authState: AuthState, onSuccess: @escaping () -> Void) {
        guard !oldPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match"
            return
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return
        }
        
        guard let token = authState.authToken else {
            errorMessage = "Not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await authService.changePassword(oldPassword: oldPassword, newPassword: newPassword, token: token)
                HapticFeedback.success()
                isLoading = false
                showSuccess = true
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                onSuccess()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
