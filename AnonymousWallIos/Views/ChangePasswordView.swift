//
//  ChangePasswordView.swift
//  AnonymousWallIos
//
//  Change password view
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authState: AuthState
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
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
                    
                    SecureField("Enter current password", text: $oldPassword)
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
                    
                    SecureField("Enter new password", text: $newPassword)
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
                    
                    SecureField("Confirm new password", text: $confirmPassword)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Change password button
                Button(action: changePassword) {
                    if isLoading {
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
                .background(isButtonDisabled ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(isButtonDisabled)
                
                Spacer()
                
                // Cancel button
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .alert("Password Changed", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been changed successfully.")
            }
        }
    }
    
    private var isButtonDisabled: Bool {
        oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading
    }
    
    private func changePassword() {
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
        
        // Validate new password is different from old
        guard newPassword != oldPassword else {
            errorMessage = "New password must be different from current password"
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
                try await AuthService.shared.changePassword(oldPassword: oldPassword, newPassword: newPassword, token: token, userId: userId)
                await MainActor.run {
                    isLoading = false
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
    ChangePasswordView()
        .environmentObject(AuthState())
}
