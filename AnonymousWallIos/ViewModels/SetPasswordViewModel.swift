//
//  SetPasswordViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for SetPasswordView - handles initial password setup
//

import SwiftUI

@MainActor
class SetPasswordViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var password = ""
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
    
    deinit {
        #if DEBUG
        Logger.app.debug("✅ SetPasswordViewModel deinitialized")
        #endif
    }
    
    // MARK: - Computed Properties
    var isButtonDisabled: Bool {
        password.isEmpty || confirmPassword.isEmpty || isLoading
    }
    
    // MARK: - Public Methods
    func setPassword(authState: AuthState, onSuccess: @escaping () -> Void) {
        guard !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return
        }
        
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.setPassword(password: password, token: token, userId: userId)
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
