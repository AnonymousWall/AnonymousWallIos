//
//  ForgotPasswordViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for ForgotPasswordView - handles password reset
//

import SwiftUI
import Combine

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var verificationCode = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var isSendingCode = false
    @Published var errorMessage: String?
    @Published var codeSent = false
    @Published var showSuccess = false
    @Published var resendCountdown = 0
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private var countdownTimer: Timer?
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    func requestReset() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard ValidationUtils.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isSendingCode = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await authService.sendEmailVerificationCode(email: email, purpose: "password-reset")
                isSendingCode = false
                codeSent = true
                startCountdownTimer()
            } catch {
                isSendingCode = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func resetPassword(authState: AuthState, onSuccess: @escaping () -> Void) {
        guard !email.isEmpty, !verificationCode.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await authService.resetPassword(email: email, code: verificationCode, newPassword: newPassword)
                HapticFeedback.success()
                isLoading = false
                showSuccess = true
                
                // Log the user in with the new credentials
                authState.login(user: response.user, token: response.accessToken)
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                onSuccess()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func cleanup() {
        stopCountdownTimer()
    }
    
    // MARK: - Private Methods
    private func startCountdownTimer() {
        resendCountdown = 60
        stopCountdownTimer()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.resendCountdown > 0 {
                    self.resendCountdown -= 1
                } else {
                    self.stopCountdownTimer()
                }
            }
        }
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}
