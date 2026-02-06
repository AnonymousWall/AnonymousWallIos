//
//  CreatePostTabView.swift
//  AnonymousWallIos
//
//  Tab view wrapper for creating posts
//

import SwiftUI

struct CreatePostTabView: View {
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Create Post")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Share your thoughts with the community")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    showCreatePost = true
                }) {
                    Text("Create New Post")
                        .fontWeight(.semibold)
                        .frame(maxWidth: 300)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(onPostCreated: {
                // Post created successfully
                showCreatePost = false
            })
        }
    }
}

#Preview {
    CreatePostTabView()
        .environmentObject(AuthState())
}
