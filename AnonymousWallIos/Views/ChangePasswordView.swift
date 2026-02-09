//
//  ChangePasswordView.swift
//  AnonymousWallIos
//
//  Change password view
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel: ChangePasswordViewModel
    @Environment(\.dismiss) var dismiss
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        _viewModel = StateObject(wrappedValue: ChangePasswordViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "lock.shield")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    
                    Text("Change Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Update your password")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Old password input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Password")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("Enter current password", text: $viewModel.oldPassword)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // New password input
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("Enter new password", text: $viewModel.newPassword)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Confirm password input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm New Password")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("Confirm new password", text: $viewModel.confirmPassword)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Change password button
                Button(action: {
                    viewModel.changePassword(authState: authState, onSuccess: { dismiss() })
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Change Password")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 50)
                .background(viewModel.isButtonDisabled ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(viewModel.isButtonDisabled)
                
                Spacer()
                
                // Cancel button
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .alert("Password Changed", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been changed successfully.")
            }
        }
    }
}

#Preview {
    ChangePasswordView()
        .environmentObject(AuthState())
}
