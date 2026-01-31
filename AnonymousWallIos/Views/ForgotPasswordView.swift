//
//  ForgotPasswordView.swift
//  AnonymousWallIos
//
//  Password reset view
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authState: AuthState
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var isSendingCode = false
    @State private var errorMessage: String?
    @State private var codeSent = false
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "lock.rotation")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    
                    Text("Reset Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(codeSent ? "Enter the code and new password" : "Enter your email to reset password")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        TextField("Enter your email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .disabled(codeSent)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        if !codeSent {
                            Button(action: requestReset) {
                                if isSendingCode {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text("Send Code")
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(email.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(email.isEmpty || isSendingCode)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Verification code and password inputs (shown after code is sent)
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Enter new password", text: $newPassword)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Confirm new password", text: $confirmPassword)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: requestReset) {
                        Text("Resend Code")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Reset password button (shown after code is sent)
                if codeSent {
                    Button(action: resetPassword) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Reset Password")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 50)
                    .background(isResetButtonDisabled ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(isResetButtonDisabled)
                }
                
                Spacer()
                
                // Cancel button
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .alert("Password Reset Successful", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been reset. You are now logged in.")
            }
        }
    }
    
    private var isResetButtonDisabled: Bool {
        verificationCode.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading
    }
    
    private func requestReset() {
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
                try await AuthService.shared.requestPasswordReset(email: email)
                await MainActor.run {
                    isSendingCode = false
                    codeSent = true
                }
            } catch {
                await MainActor.run {
                    isSendingCode = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func resetPassword() {
        // Validate passwords match
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        // Validate password length
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await AuthService.shared.resetPassword(email: email, code: verificationCode, newPassword: newPassword)
                await MainActor.run {
                    isLoading = false
                    // User is now logged in with new password
                    authState.login(user: response.user, token: response.accessToken, needsPasswordSetup: false)
                    showSuccess = true
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
    ForgotPasswordView()
        .environmentObject(AuthState())
}
