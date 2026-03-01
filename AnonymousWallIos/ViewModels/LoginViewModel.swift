//
//  LoginViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for LoginView - handles login business logic
//

import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var verificationCode = ""
    @Published var isLoading = false
    @Published var isSendingCode = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var loginMethod: LoginMethod = .password
    @Published var resendCountdown = 0
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private var countdownTimer: Timer?
    
    // MARK: - Enums
    enum LoginMethod {
        case password
        case verificationCode
    }
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    deinit {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    // MARK: - Computed Properties
    var isLoginButtonDisabled: Bool {
        if loginMethod == .password {
            return email.isEmpty || password.isEmpty || isLoading
        } else {
            return email.isEmpty || verificationCode.isEmpty || isLoading
        }
    }
    
    // MARK: - Public Methods
    func requestVerificationCode() {
        guard !email.isEmpty else { return }
        
        // Validate email format
        guard ValidationUtils.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isSendingCode = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                _ = try await authService.sendEmailVerificationCode(email: email, purpose: "login")
                isSendingCode = false
                successMessage = "Verification code sent to your email!"
                startCountdownTimer()
            } catch {
                isSendingCode = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func login(authState: AuthState) {
        guard !email.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let response: AuthResponse
                
                if loginMethod == .password {
                    response = try await authService.loginWithPassword(email: email, password: password)
                } else {
                    response = try await authService.loginWithEmailCode(email: email, code: verificationCode)
                }
                
                HapticFeedback.success()
                isLoading = false
                // User is logging in - passwordSet from API indicates password status
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
