//
//  AuthenticationView.swift
//  AnonymousWallIos
//
//  Root authentication view
//

import SwiftUI

struct AuthenticationView: View {
    @State private var showLogin = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo/Icon
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                // App Name
                Text("Anonymous Wall")
                    .font(.system(size: 36, weight: .bold))
                
                Text("Your Voice, Your Community")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Get Started Button
                NavigationLink(destination: RegistrationView()) {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Login Button
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AuthenticationView()
}
