//
//  SetPasswordView.swift
//  AnonymousWallIos
//
//  Initial password setup view
//

import SwiftUI

struct SetPasswordView: View {
    @EnvironmentObject var authState: AuthState
    @State private var password = ""
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
                    Image(systemName: "key.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    
                    Text("Set Your Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create a secure password for your account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Password input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("Enter password", text: $password)
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
                    Text("Confirm Password")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("Confirm password", text: $confirmPassword)
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
                
                // Set password button
                Button(action: setPassword) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Set Password")
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
                
                // Skip for now option
                Button(action: { dismiss() }) {
                    Text("Skip for now")
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .alert("Password Set Successfully", isPresented: $showSuccess) {
                Button("OK") {
                    authState.updatePasswordSetupStatus(completed: true)
                    dismiss()
                }
            } message: {
                Text("Your password has been set. You can now use it to login.")
            }
        }
    }
    
    private var isButtonDisabled: Bool {
        password.isEmpty || confirmPassword.isEmpty || isLoading
    }
    
    private func setPassword() {
        // Validate passwords match
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        // Validate password length
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
                try await AuthService.shared.setPassword(password: password, token: token, userId: userId)
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
    SetPasswordView()
        .environmentObject(AuthState())
}
