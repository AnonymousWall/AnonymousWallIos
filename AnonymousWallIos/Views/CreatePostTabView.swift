//
//  CreatePostTabView.swift
//  AnonymousWallIos
//
//  Tab view wrapper for creating posts, internships, and marketplace items
//

import SwiftUI

struct CreatePostTabView: View {
    @StateObject private var viewModel = CreatePostTabViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.purplePinkGradient)
                            .accessibilityHidden(true)

                        Text("Create")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Share posts, internships, or list items for sale")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 24)

                    // Create buttons
                    VStack(spacing: 16) {
                        CreateOptionButton(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "New Post",
                            subtitle: "Share your thoughts anonymously",
                            gradient: Color.purplePinkGradient,
                            action: { viewModel.showCreatePostSheet() }
                        )
                        .accessibilityLabel("Create new post")
                        .accessibilityHint("Double tap to start creating a new post")

                        CreateOptionButton(
                            icon: "briefcase.fill",
                            title: "New Internship",
                            subtitle: "Share an internship opportunity",
                            gradient: Color.tealPurpleGradient,
                            action: { viewModel.showCreateInternshipSheet() }
                        )
                        .accessibilityLabel("Create new internship posting")
                        .accessibilityHint("Double tap to post an internship opportunity")

                        CreateOptionButton(
                            icon: "cart.fill",
                            title: "New Marketplace Listing",
                            subtitle: "Buy and sell items with other students",
                            gradient: Color.orangePinkGradient,
                            action: { viewModel.showCreateMarketplaceSheet() }
                        )
                        .accessibilityLabel("Create new marketplace listing")
                        .accessibilityHint("Double tap to list an item for sale")
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostView(onPostCreated: {
                viewModel.dismissCreatePostSheet()
            })
        }
        .sheet(isPresented: $viewModel.showCreateInternship) {
            CreateInternshipView {
                viewModel.dismissCreateInternshipSheet()
            }
        }
        .sheet(isPresented: $viewModel.showCreateMarketplace) {
            CreateMarketplaceView {
                viewModel.dismissCreateMarketplaceSheet()
            }
        }
    }
}

// MARK: - Create Option Button
private struct CreateOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradient)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
        }
        .buttonStyle(.bounce)
    }
}

#Preview {
    CreatePostTabView()
        .environmentObject(AuthState())
}

