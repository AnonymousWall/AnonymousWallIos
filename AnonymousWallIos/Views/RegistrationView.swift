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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(codeSent ? "Enter the code sent to your email" : "Enter your email to get started")
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
                            Button(action: sendVerificationCode) {
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
                
                // Register button (shown after code is sent)
                if codeSent {
                    Button(action: registerUser) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Register")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 50)
                    .background(verificationCode.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(verificationCode.isEmpty || isLoading)
                }
                
                Spacer()
                
                // Login link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    NavigationLink("Login", destination: LoginView())
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Create Account")
            .alert("Registration Successful", isPresented: $showingSuccess) {
                Button("OK") {}
            } message: {
                Text("You are now logged in. Please set up your password to secure your account.")
            }
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
    
    private func registerUser() {
        guard !email.isEmpty && !verificationCode.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await AuthService.shared.registerWithEmail(email: email, code: verificationCode)
                await MainActor.run {
                    isLoading = false
                    // User is now logged in after registration
                    // Password setup is required for new registrations
                    authState.login(user: response.user, token: response.accessToken, needsPasswordSetup: true)
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
