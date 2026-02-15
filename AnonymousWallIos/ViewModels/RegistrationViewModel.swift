//
//  RegistrationViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for RegistrationView - handles registration business logic
//

import SwiftUI
import Combine

@MainActor
class RegistrationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var verificationCode = ""
    @Published var isLoading = false
    @Published var isSendingCode = false
    @Published var errorMessage: String?
    @Published var codeSent = false
    @Published var showingSuccess = false
    @Published var resendCountdown = 0
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private var countdownTimer: Timer?
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    deinit {
        #if DEBUG
        Logger.app.debug("✅ RegistrationViewModel deinitialized")
        #endif
        cleanup()
    }
    
    // MARK: - Public Methods
    func sendVerificationCode() {
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
                _ = try await authService.sendEmailVerificationCode(email: email, purpose: "register")
                isSendingCode = false
                codeSent = true
                startCountdownTimer()
            } catch {
                isSendingCode = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func register(authState: AuthState) {
        guard !email.isEmpty, !verificationCode.isEmpty else {
            errorMessage = "Please enter both email and verification code"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await authService.registerWithEmail(email: email, code: verificationCode)
                HapticFeedback.success()
                isLoading = false
                showingSuccess = true
                
                // Auto-login after successful registration
                authState.login(user: response.user, token: response.accessToken)
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
