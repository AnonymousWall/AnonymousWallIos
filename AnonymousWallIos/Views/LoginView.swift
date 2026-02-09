//
//  LoginView.swift
//  AnonymousWallIos
//
//  User login view
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var viewModel: LoginViewModel
    @State private var showForgotPassword = false
    
    init(prefillEmail: String? = nil, authService: AuthServiceProtocol = AuthService.shared) {
        let vm = LoginViewModel(authService: authService)
        _viewModel = StateObject(wrappedValue: vm)
        if let email = prefillEmail {
            vm.email = email
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.purplePinkGradient)
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.primaryPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "lock.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Login to your account")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 40)
                
                // Login method selector
                Picker("Login Method", selection: $viewModel.loginMethod) {
                    Text("Password").tag(LoginViewModel.LoginMethod.password)
                    Text("Verification Code").tag(LoginViewModel.LoginMethod.verificationCode)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextField("Enter your email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            
            // Password or Verification Code based on selected method
            if viewModel.loginMethod == .password {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("Enter your password", text: $viewModel.password)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Forgot password link
                HStack {
                    Spacer()
                    Button(action: { showForgotPassword = true }) {
                        Text("Forgot Password?")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            } else {
                // Verification code input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification Code")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        TextField("Enter 6-digit code", text: $viewModel.verificationCode)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        Button(action: { viewModel.requestVerificationCode() }) {
                            if viewModel.isSendingCode {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else if viewModel.resendCountdown > 0 {
                                Text("\(viewModel.resendCountdown)s")
                                    .fontWeight(.semibold)
                            } else {
                                Text("Get Code")
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
                .padding(.horizontal)
            }
            
            // Success message
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // Login button
            Button(action: {
                HapticFeedback.light()
                viewModel.login(authState: authState)
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                        Text("Login")
                            .fontWeight(.bold)
                            .font(.system(size: 18))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 56)
            .background(
                viewModel.isLoginButtonDisabled 
                ? AnyShapeStyle(Color.gray)
                : AnyShapeStyle(Color.purplePinkGradient)
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: viewModel.isLoginButtonDisabled ? Color.clear : Color.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            .disabled(viewModel.isLoginButtonDisabled)
            
            Spacer(minLength: 20)
            
            // Registration link
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                NavigationLink("Sign Up", destination: RegistrationView())
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.cleanup()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(authService: AuthService.shared)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthState())
}
