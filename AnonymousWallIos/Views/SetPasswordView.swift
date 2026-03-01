//
//  SetPasswordView.swift
//  AnonymousWallIos
//
//  Initial password setup view
//

import SwiftUI

struct SetPasswordView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel: SetPasswordViewModel
    @Environment(\.dismiss) var dismiss
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        _viewModel = StateObject(wrappedValue: SetPasswordViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentPurple)
                    
                    Text("Set Your Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create a secure password for your account")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Password input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    SecureField("Enter password", text: $viewModel.password)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.surfaceSecondary)
                        .cornerRadius(10)
                    
                    Text("Password must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal)
                
                // Confirm password input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    SecureField("Confirm password", text: $viewModel.confirmPassword)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.surfaceSecondary)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.accentRed)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Set password button
                Button(action: {
                    viewModel.setPassword(authState: authState, onSuccess: {
                        authState.updatePasswordSetupStatus(completed: true)
                        dismiss()
                    })
                }) {
                    if viewModel.isLoading {
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
                .background(viewModel.isButtonDisabled ? AnyShapeStyle(Color.gray) : AnyShapeStyle(LinearGradient.brandGradient))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(viewModel.isButtonDisabled)
                
                Spacer()
                
                // Skip for now option
                Button(action: { dismiss() }) {
                    Text("Skip for now")
                        .foregroundColor(.textSecondary)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .background(Color.appBackground.ignoresSafeArea())
            .alert("Password Set Successfully", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    authState.updatePasswordSetupStatus(completed: true)
                    dismiss()
                }
            } message: {
                Text("Your password has been set. You can now use it to login.")
            }
        }
    }
}

#Preview {
    SetPasswordView()
        .environmentObject(AuthState())
}
