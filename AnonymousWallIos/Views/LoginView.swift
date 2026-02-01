//
//  LoginView.swift
//  AnonymousWallIos
//
//  User login view
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authState: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var isSendingCode = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var loginMethod: LoginMethod = .password
    @State private var showForgotPassword = false
    
    var prefillEmail: String?
    
    enum LoginMethod {
        case password
        case verificationCode
    }
    
    init(prefillEmail: String? = nil) {
        self.prefillEmail = prefillEmail
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "lock.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Login to your account")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            
            // Login method selector
            Picker("Login Method", selection: $loginMethod) {
                Text("Password").tag(LoginMethod.password)
                Text("Verification Code").tag(LoginMethod.verificationCode)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Spacer()
            
            // Email input
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter your email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Password or Verification Code based on selected method
            if loginMethod == .password {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("Enter your password", text: $password)
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
                        TextField("Enter 6-digit code", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        Button(action: requestVerificationCode) {
                            if isSendingCode {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Get Code")
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
                .padding(.horizontal)
            }
            
            // Success message
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // Login button
            Button(action: loginUser) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Login")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 50)
            .background(isLoginButtonDisabled ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(isLoginButtonDisabled)
            
            Spacer()
            
            // Registration link
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                NavigationLink("Sign Up", destination: RegistrationView())
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let prefillEmail = prefillEmail {
                email = prefillEmail
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private var isLoginButtonDisabled: Bool {
        if loginMethod == .password {
            return email.isEmpty || password.isEmpty || isLoading
        } else {
            return email.isEmpty || verificationCode.isEmpty || isLoading
        }
    }
    
    private func requestVerificationCode() {
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
                _ = try await AuthService.shared.sendEmailVerificationCode(email: email, purpose: "login")
                await MainActor.run {
                    isSendingCode = false
                    successMessage = "Verification code sent to your email!"
                }
            } catch {
                await MainActor.run {
                    isSendingCode = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loginUser() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let response: AuthResponse
                
                if loginMethod == .password {
                    response = try await AuthService.shared.loginWithPassword(email: email, password: password)
                } else {
                    response = try await AuthService.shared.loginWithEmailCode(email: email, code: verificationCode)
                }
                
                await MainActor.run {
                    isLoading = false
                    // User is logging in (password should already be set)
                    // Note: Backend should ideally indicate password setup status in response
                    authState.login(user: response.user, token: response.accessToken, needsPasswordSetup: false)
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
    LoginView()
        .environmentObject(AuthState())
}
