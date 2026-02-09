//
//  RegistrationView.swift
//  AnonymousWallIos
//
//  User registration view
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel: RegistrationViewModel
    @ObservedObject var coordinator: AuthCoordinator
    
    init(coordinator: AuthCoordinator, authService: AuthServiceProtocol = AuthService.shared) {
        self.coordinator = coordinator
        _viewModel = StateObject(wrappedValue: RegistrationViewModel(authService: authService))
    }
    
    var body: some View {
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
                            
                            Text(viewModel.codeSent ? "Enter the code sent to your email" : "Enter your email to get started")
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
                            TextField("Enter your email", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .disabled(viewModel.codeSent)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            if !viewModel.codeSent {
                                Button(action: {
                                    HapticFeedback.light()
                                    viewModel.sendVerificationCode()
                                }) {
                                    if viewModel.isSendingCode {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else if viewModel.resendCountdown > 0 {
                                        Text("\(viewModel.resendCountdown)s")
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
                                .background((viewModel.email.isEmpty || viewModel.resendCountdown > 0) ? AnyShapeStyle(Color.gray) : AnyShapeStyle(Color.tealPurpleGradient))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: (viewModel.email.isEmpty || viewModel.resendCountdown > 0) ? Color.clear : Color.vibrantTeal.opacity(0.3), radius: 4, x: 0, y: 2)
                                .disabled(viewModel.email.isEmpty || viewModel.isSendingCode || viewModel.resendCountdown > 0)
                            }
                        }
                    }
                    .padding(.horizontal)
                
                // Verification code input (shown after code is sent)
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
                    
                    Button(action: { viewModel.sendVerificationCode() }) {
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
                
                // Register button (shown after code is sent)
                if viewModel.codeSent {
                    Button(action: {
                        HapticFeedback.light()
                        viewModel.register(authState: authState)
                    }) {
                        if viewModel.isLoading {
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
                        viewModel.verificationCode.isEmpty 
                        ? AnyShapeStyle(Color.gray)
                        : AnyShapeStyle(Color.tealPurpleGradient)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: viewModel.verificationCode.isEmpty ? Color.clear : Color.vibrantTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    .disabled(viewModel.verificationCode.isEmpty || viewModel.isLoading)
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
            viewModel.cleanup()
        }
        .alert("Registration Successful", isPresented: $viewModel.showingSuccess) {
            Button("OK") {}
        } message: {
            Text("You are now logged in. Please set up your password to secure your account.")
        }
    }
}

#Preview {
    RegistrationView(coordinator: AuthCoordinator())
        .environmentObject(AuthState())
}
