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
    @State private var postTitle = ""
    @State private var postContent = ""
    @State private var selectedWall: WallType = .campus
    @State private var isPosting = false
    @State private var errorMessage: String?
    
    var onPostCreated: () -> Void
    
    private let maxTitleCharacters = 255
    private let maxContentCharacters = 5000
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Wall selection
                Picker("Wall", selection: $selectedWall) {
                    ForEach(WallType.allCases, id: \.self) { wallType in
                        Text(wallType.displayName).tag(wallType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 10)
                .onChange(of: selectedWall) { _, _ in
                    HapticFeedback.selection()
                }
                
                // Title input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Enter post title", text: $postTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    HStack {
                        Spacer()
                        Text("\(postTitle.count)/\(maxTitleCharacters)")
                            .font(.caption)
                            .foregroundColor(postTitle.count > maxTitleCharacters ? .red : .gray)
                    }
                    .padding(.horizontal)
                }
                
                // Content section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Character count for content
                    HStack {
                        Spacer()
                        Text("\(postContent.count)/\(maxContentCharacters)")
                            .font(.caption)
                            .foregroundColor(postContent.count > maxContentCharacters ? .red : .gray)
                    }
                    .padding(.horizontal)
                    
                    // Text editor
                    TextEditor(text: $postContent)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Post button
                Button(action: {
                    HapticFeedback.success()
                    createPost()
                }) {
                    if isPosting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                            Text("Post")
                                .fontWeight(.bold)
                                .font(.system(size: 18))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 56)
                .background(
                    isPostButtonDisabled 
                    ? Color.gray 
                    : Color.purplePinkGradient
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: isPostButtonDisabled ? Color.clear : Color.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
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
        postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        postTitle.count > maxTitleCharacters ||
        postContent.count > maxContentCharacters ||
        isPosting
    }
    
    private func createPost() {
        let trimmedTitle = postTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Post title cannot be empty"
            return
        }
        
        guard trimmedTitle.count <= maxTitleCharacters else {
            errorMessage = "Post title exceeds maximum length of \(maxTitleCharacters) characters"
            return
        }
        
        guard !trimmedContent.isEmpty else {
            errorMessage = "Post content cannot be empty"
            return
        }
        
        guard trimmedContent.count <= maxContentCharacters else {
            errorMessage = "Post content exceeds maximum length of \(maxContentCharacters) characters"
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
                _ = try await PostService.shared.createPost(title: trimmedTitle, content: trimmedContent, wall: selectedWall, token: token, userId: userId)
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
