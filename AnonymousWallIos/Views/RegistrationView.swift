//
//  RegistrationView.swift
//  AnonymousWallIos
//
//  User registration view
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authState: AuthState
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var isSendingCode = false
    @State private var errorMessage: String?
    @State private var codeSent = false
    @State private var showingSuccess = false
    @State private var resendCountdown = 0
    @State private var countdownTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.tealPurpleGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.vibrantTeal.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                            
                            Text(codeSent ? "Enter the code sent to your email" : "Enter your email to get started")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Email input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("Enter your email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .disabled(codeSent)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            if !codeSent {
                                Button(action: {
                                    HapticFeedback.light()
                                    sendVerificationCode()
                                }) {
                                    if isSendingCode {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else if resendCountdown > 0 {
                                        Text("\(resendCountdown)s")
                                            .fontWeight(.bold)
                                            .font(.system(size: 14))
                                    } else {
                                        Text("Get Code")
                                            .fontWeight(.bold)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background((email.isEmpty || resendCountdown > 0) ? AnyShapeStyle(Color.gray) : AnyShapeStyle(Color.tealPurpleGradient))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: (email.isEmpty || resendCountdown > 0) ? Color.clear : Color.vibrantTeal.opacity(0.3), radius: 4, x: 0, y: 2)
                                .disabled(email.isEmpty || isSendingCode || resendCountdown > 0)
                            }
                        }
                    }
                    .padding(.horizontal)
                
                // Verification code input (shown after code is sent)
                if codeSent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Code")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter 6-digit code", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: sendVerificationCode) {
                        if resendCountdown > 0 {
                            Text("Resend Code in \(resendCountdown)s")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Resend Code")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(resendCountdown > 0)
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Register button (shown after code is sent)
                if codeSent {
                    Button(action: {
                        HapticFeedback.light()
                        registerUser()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Register")
                                    .fontWeight(.bold)
                                    .font(.system(size: 18))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 56)
                    .background(
                        verificationCode.isEmpty 
                        ? AnyShapeStyle(Color.gray)
                        : AnyShapeStyle(Color.tealPurpleGradient)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: verificationCode.isEmpty ? Color.clear : Color.vibrantTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    .disabled(verificationCode.isEmpty || isLoading)
                }
                
                Spacer(minLength: 20)
                
                // Login link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    NavigationLink("Login", destination: LoginView())
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Create Account")
        .onDisappear {
            stopCountdownTimer()
        }
        .alert("Registration Successful", isPresented: $showingSuccess) {
            Button("OK") {}
        } message: {
            Text("You are now logged in. Please set up your password to secure your account.")
        }
    }
    
    private func sendVerificationCode() {
        guard !email.isEmpty else { return }
        
        // Validate email format
        guard ValidationUtils.isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isSendingCode = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await AuthService.shared.sendEmailVerificationCode(email: email, purpose: "register")
                await MainActor.run {
                    HapticFeedback.success()
                    isSendingCode = false
                    codeSent = true
                    startCountdownTimer()
                }
            } catch {
                await MainActor.run {
                    isSendingCode = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func startCountdownTimer() {
        resendCountdown = 60
        stopCountdownTimer()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
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
    
    private func registerUser() {
        guard !email.isEmpty && !verificationCode.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await AuthService.shared.registerWithEmail(email: email, code: verificationCode)
                await MainActor.run {
                    HapticFeedback.success()
                    isLoading = false
                    // User is now logged in after registration
                    // passwordSet from API will indicate if password setup is required
                    authState.login(user: response.user, token: response.accessToken)
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthState())
}
