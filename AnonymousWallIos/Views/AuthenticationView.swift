//
//  AuthenticationView.swift
//  AnonymousWallIos
//
//  Root authentication view
//

import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var coordinator: AuthCoordinator
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                // Gradient background
                Color.purplePinkGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // App Logo/Icon with gradient
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)
                            
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        
                        // App Name
                        VStack(spacing: 8) {
                            Text("Anonymous Wall")
                                .font(.system(size: 42, weight: .heavy))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            Text("Your Voice, Your Community")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Get Started Button
                        Button {
                            coordinator.navigate(to: .registration)
                        } label: {
                            HStack {
                                Text("Get Started")
                                    .fontWeight(.bold)
                                    .font(.system(size: 18))
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .foregroundColor(.primaryPurple)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 30)
                        
                        // Login Button
                        Button {
                            coordinator.navigate(to: .login)
                        } label: {
                            Text("Login")
                                .fontWeight(.semibold)
                                .font(.system(size: 18))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white.opacity(0.25))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AuthCoordinator.Destination.self) { destination in
                switch destination {
                case .login:
                    LoginView(coordinator: coordinator)
                case .registration:
                    RegistrationView(coordinator: coordinator)
                case .forgotPassword:
                    EmptyView() // Handled as a sheet
                }
            }
        }
        .sheet(isPresented: $coordinator.showForgotPassword) {
            ForgotPasswordView(authService: AuthService.shared)
        }
    }
}

#Preview {
    AuthenticationView(coordinator: AuthCoordinator())
}
