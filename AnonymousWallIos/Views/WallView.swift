//
//  WallView.swift
//  AnonymousWallIos
//
//  Main wall view for authenticated users
//

import SwiftUI

struct WallView: View {
    @EnvironmentObject var authState: AuthState
    @State private var showSetPassword = false
    @State private var showChangePassword = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Password setup alert banner
                if authState.needsPasswordSetup {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Please set up your password to secure your account")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Button("Set Now") {
                            showSetPassword = true
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
                }
                
                Text("Welcome to Anonymous Wall!")
                    .font(.title)
                    .padding()
                
                if let user = authState.currentUser {
                    VStack(spacing: 8) {
                        Text("Logged in as: \(user.email)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if user.isVerified {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Verified")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Text("Post Feed Coming Soon...")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("Wall")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Change password option (only if password is set)
                        if !authState.needsPasswordSetup {
                            Button(action: { showChangePassword = true }) {
                                Label("Change Password", systemImage: "lock.shield")
                            }
                        }
                        
                        // Logout option
                        Button(role: .destructive, action: {
                            authState.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showSetPassword) {
            SetPasswordView()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .onAppear {
            // Show password setup if needed
            // Small delay to allow view to fully load before presenting sheet
            if authState.needsPasswordSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSetPassword = true
                }
            }
        }
    }
}

#Preview {
    WallView()
        .environmentObject(AuthState())
}
