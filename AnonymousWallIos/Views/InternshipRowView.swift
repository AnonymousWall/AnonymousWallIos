//
//  InternshipRowView.swift
//  AnonymousWallIos
//
//  Row view for displaying a single internship posting
//

import SwiftUI

struct InternshipRowView: View {
    let internship: Internship
    let isOwnPosting: Bool
    var onDelete: () -> Void
    var onTapAuthor: (() -> Void)?

    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @State private var showDeleteConfirmation = false
    @State private var showAuthorActionSheet = false
    @State private var showBlockSuccessAlert = false

    private var isCampus: Bool {
        internship.wall.uppercased() == WallType.campus.rawValue.uppercased()
    }

    private var wallGradient: LinearGradient {
        LinearGradient.brandGradient
    }

    private var wallDisplayName: String {
        isCampus ? WallType.campus.displayName : WallType.national.displayName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Wall badge and author
            HStack(spacing: 10) {
                Text(wallDisplayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(wallGradient)
                    .cornerRadius(12)
                    .accessibilityLabel("Posted on \(wallDisplayName) wall")

                if isOwnPosting {
                    Text("by Me")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.textSecondary)
                        .accessibilityLabel("Posted by you")
                } else {
                    Button(action: {
                        HapticFeedback.selection()
                        showAuthorActionSheet = true
                    }) {
                        Text("by \(internship.author.profileName)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .accessibilityLabel("Posted by \(internship.author.profileName)")
                    .accessibilityHint("Double tap to message or block \(internship.author.profileName)")
                    .confirmationDialog(
                        internship.author.profileName,
                        isPresented: $showAuthorActionSheet,
                        titleVisibility: .visible
                    ) {
                        Button("Message \(internship.author.profileName)") {
                            onTapAuthor?()
                        }
                        Button("Block \(internship.author.profileName)", role: .destructive) {
                            HapticFeedback.warning()
                            blockViewModel.blockUser(targetUserId: internship.author.id, authState: authState) {
                                showBlockSuccessAlert = true
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }

                Spacer()
            }

            // Company and role
            VStack(alignment: .leading, spacing: 4) {
                Text(internship.company)
                    .font(.title3.bold())
                    .foregroundColor(.textPrimary)
                    .accessibilityLabel("Company: \(internship.company)")

                Text(internship.role)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .accessibilityLabel("Role: \(internship.role)")
            }

            // Details chips
            HStack(spacing: 8) {
                if let salary = internship.salary, !salary.isEmpty {
                    DetailChip(icon: "dollarsign.circle", text: salary, color: .green)
                }
                if let location = internship.location, !location.isEmpty {
                    DetailChip(icon: "mappin.circle", text: location, color: .blue)
                }
                if let deadline = internship.deadline, !deadline.isEmpty {
                    DetailChip(icon: "calendar", text: deadline, color: .orange)
                }
            }

            // Footer
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                    Text(DateFormatting.formatRelativeTime(internship.createdAt))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Posted \(DateFormatting.formatRelativeTime(internship.createdAt))")

                Spacer()

                // Comment count
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.fill")
                        .font(.callout)
                        .foregroundColor(.accentBlue)
                    Text("\(internship.comments)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentBlue)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accentBlue.opacity(0.15))
                .cornerRadius(8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(internship.comments) comments")

                // Delete button (own postings only)
                if isOwnPosting {
                    Button(action: {
                        HapticFeedback.warning()
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.accentRed)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.bounce)
                    .accessibilityLabel("Delete internship posting")
                    .accessibilityHint("Double tap to delete this posting")
                    .confirmationDialog(
                        "Delete Posting",
                        isPresented: $showDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) { onDelete() }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete this internship posting?")
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfacePrimary)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderSubtle, lineWidth: 0.5)
        )
        .alert("User Blocked", isPresented: $showBlockSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(internship.author.profileName) has been blocked.")
        }
        .alert("Error", isPresented: .init(
            get: { blockViewModel.errorMessage != nil },
            set: { if !$0 { blockViewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { blockViewModel.errorMessage = nil }
        } message: {
            if let error = blockViewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Detail Chip
private struct DetailChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    InternshipRowView(
        internship: Internship(
            id: "1",
            company: "Google",
            role: "Software Engineer Intern",
            salary: "$8000/month",
            location: "Mountain View, CA",
            description: "Work on cutting-edge projects.",
            deadline: "2026-06-30",
            wall: "CAMPUS",
            comments: 3,
            author: Post.Author(id: "user1", profileName: "Anonymous", isAnonymous: false),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        ),
        isOwnPosting: false,
        onDelete: {}
    )
    .padding()
    .environmentObject(AuthState())
    .environmentObject(BlockViewModel())
}