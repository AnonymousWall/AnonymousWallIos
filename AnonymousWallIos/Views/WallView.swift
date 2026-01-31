//
//  WallView.swift
//  AnonymousWallIos
//
//  Main wall view for authenticated users
//

import SwiftUI

struct WallView: View {
    @EnvironmentObject var authState: AuthState
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome to Anonymous Wall!")
                    .font(.title)
                    .padding()
                
                if let user = authState.currentUser {
                    Text("Logged in as: \(user.email)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Spacer()
                
                Text("Post Feed Coming Soon...")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Logout button
                Button(action: {
                    authState.logout()
                }) {
                    Text("Logout")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Wall")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WallView()
        .environmentObject(AuthState())
}
