//
//  ForgotPasswordView.swift
//  AnonymousWallIos
//
//  Password reset view
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel: ForgotPasswordViewModel
    @Environment(\.dismiss) var dismiss
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        _viewModel = StateObject(wrappedValue: ForgotPasswordViewModel(authService: authService))
    }
    
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
                    
                    Text(viewModel.codeSent ? "Enter the code and new password" : "Enter your email to reset password")
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
                        TextField("Enter your email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .disabled(viewModel.codeSent)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        if !viewModel.codeSent {
                            Button(action: { viewModel.requestReset() }) {
                                if viewModel.isSendingCode {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else if viewModel.resendCountdown > 0 {
                                    Text("\(viewModel.resendCountdown)s")
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Send Code")
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background((viewModel.email.isEmpty || viewModel.resendCountdown > 0) ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(viewModel.email.isEmpty || viewModel.isSendingCode || viewModel.resendCountdown > 0)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Verification code and password inputs (shown after code is sent)
                if viewModel.codeSent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Code")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter 6-digit code", text: $viewModel.verificationCode)
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
                        
                        SecureField("Enter new password", text: $viewModel.newPassword)
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
                        
                        SecureField("Confirm new password", text: $viewModel.confirmPassword)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: { viewModel.requestReset() }) {
                        if viewModel.resendCountdown > 0 {
                            Text("Resend Code in \(viewModel.resendCountdown)s")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Resend Code")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(viewModel.resendCountdown > 0)
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Reset password button (shown after code is sent)
                if viewModel.codeSent {
                    Button(action: { 
                        viewModel.resetPassword(authState: authState, onSuccess: { dismiss() }) 
                    }) {
                        if viewModel.isLoading {
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
                    .background((viewModel.verificationCode.isEmpty || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty || viewModel.isLoading) ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(viewModel.verificationCode.isEmpty || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty || viewModel.isLoading)
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
            .onDisappear {
                viewModel.cleanup()
            }
            .alert("Password Reset Successful", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been reset. You are now logged in.")
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthState())
}
