//
//  CreatePostView.swift
//  AnonymousWallIos
//
//  View for creating a new post
//

import SwiftUI

struct CreatePostView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    @State private var postContent = ""
    @State private var selectedWall = "campus"
    @State private var isPosting = false
    @State private var errorMessage: String?
    
    var onPostCreated: () -> Void
    
    private let maxCharacters = 500
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Wall selection
                Picker("Wall", selection: $selectedWall) {
                    Text("Campus").tag("campus")
                    Text("National").tag("national")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Character count
                HStack {
                    Spacer()
                    Text("\(postContent.count)/\(maxCharacters)")
                        .font(.caption)
                        .foregroundColor(postContent.count > maxCharacters ? .red : .gray)
                }
                .padding(.horizontal)
                
                // Text editor
                TextEditor(text: $postContent)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Post button
                Button(action: createPost) {
                    if isPosting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Post")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 50)
                .background(isPostButtonDisabled ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .disabled(isPostButtonDisabled)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isPostButtonDisabled: Bool {
        postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        postContent.count > maxCharacters ||
        isPosting
    }
    
    private func createPost() {
        let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else {
            errorMessage = "Post cannot be empty"
            return
        }
        
        guard trimmedContent.count <= maxCharacters else {
            errorMessage = "Post exceeds maximum length"
            return
        }
        
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }
        
        isPosting = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await PostService.shared.createPost(content: trimmedContent, wall: selectedWall, token: token, userId: userId)
                await MainActor.run {
                    isPosting = false
                    onPostCreated()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPosting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    CreatePostView(onPostCreated: {})
        .environmentObject(AuthState())
}
