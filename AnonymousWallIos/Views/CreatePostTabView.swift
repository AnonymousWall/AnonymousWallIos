//
//  CreatePostTabView.swift
//  AnonymousWallIos
//
//  Tab view wrapper for creating posts
//

import SwiftUI

struct CreatePostTabView: View {
    @StateObject private var viewModel = CreatePostTabViewModel()
    
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
                    viewModel.showCreatePostSheet()
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
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostView(onPostCreated: {
                // Post created successfully
                viewModel.dismissCreatePostSheet()
            })
        }
    }
}

#Preview {
    CreatePostTabView()
        .environmentObject(AuthState())
}
