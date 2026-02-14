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
    @StateObject private var viewModel = CreatePostViewModel()
    
    var onPostCreated: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Wall selection
                Picker("Wall", selection: $viewModel.selectedWall) {
                    ForEach(WallType.allCases, id: \.self) { wallType in
                        Text(wallType.displayName).tag(wallType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 10)
                .accessibilityLabel("Select wall type")
                .accessibilityValue(viewModel.selectedWall.displayName)
                .onChange(of: viewModel.selectedWall) { _, _ in
                    HapticFeedback.selection()
                }
                
                // Title input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .padding(.horizontal)
                        .accessibilityAddTraits(.isHeader)
                    
                    TextField("Enter post title", text: $viewModel.postTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .accessibilityLabel("Post title")
                        .accessibilityHint("Enter the title for your post")
                    
                    HStack {
                        Spacer()
                        Text("\(viewModel.titleCharacterCount)/\(viewModel.maxTitleCount)")
                            .font(.caption)
                            .foregroundColor(viewModel.isTitleOverLimit ? .red : .gray)
                            .accessibilityLabel("Character count: \(viewModel.titleCharacterCount) of \(viewModel.maxTitleCount)")
                    }
                    .padding(.horizontal)
                }
                
                // Content section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                        .padding(.horizontal)
                        .accessibilityAddTraits(.isHeader)
                    
                    // Character count for content
                    HStack {
                        Spacer()
                        Text("\(viewModel.contentCharacterCount)/\(viewModel.maxContentCount)")
                            .font(.caption)
                            .foregroundColor(viewModel.isContentOverLimit ? .red : .gray)
                            .accessibilityLabel("Character count: \(viewModel.contentCharacterCount) of \(viewModel.maxContentCount)")
                    }
                    .padding(.horizontal)
                    
                    // Text editor
                    TextEditor(text: $viewModel.postContent)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .accessibilityLabel("Post content")
                        .accessibilityHint("Enter the content for your post")
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Post button
                Button(action: {
                    HapticFeedback.light()
                    viewModel.createPost(authState: authState, onSuccess: {
                        onPostCreated()
                        dismiss()
                    })
                }) {
                    if viewModel.isPosting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                                .font(.body)
                            Text("Post")
                                .fontWeight(.bold)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 56)
                .background(
                    viewModel.isPostButtonDisabled 
                    ? AnyShapeStyle(Color.gray)
                    : AnyShapeStyle(Color.purplePinkGradient)
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: viewModel.isPostButtonDisabled ? Color.clear : Color.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .disabled(viewModel.isPostButtonDisabled)
                .accessibilityLabel("Submit post")
                .accessibilityHint(viewModel.isPostButtonDisabled ? "Button disabled. Complete the title and content to post" : "Double tap to create your post")
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Double tap to cancel creating a post")
                }
            }
        }
    }
}

#Preview {
    CreatePostView(onPostCreated: {})
        .environmentObject(AuthState())
}
