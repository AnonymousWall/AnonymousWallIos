//
//  InternshipDetailView.swift
//  AnonymousWallIos
//
//  Detail view for an internship posting showing full info and comments
//

import SwiftUI

struct InternshipDetailView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss

    @Binding var internship: Internship
    @StateObject private var viewModel = InternshipDetailViewModel()
    @State private var showDeleteConfirmation = false

    var onTapAuthor: ((String, String) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Internship detail card
                    VStack(alignment: .leading, spacing: 14) {
                        // Author line
                        HStack {
                            if internship.author.id == authState.currentUser?.id {
                                Text("Posted by Me")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Button(action: { onTapAuthor?(internship.author.id, internship.author.profileName) }) {
                                    Text("Posted by \(internship.author.profileName)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .underline()
                                }
                                .accessibilityLabel("Posted by \(internship.author.profileName)")
                                .accessibilityHint("Double tap to message \(internship.author.profileName)")
                            }
                            Spacer()
                        }

                        // Company and role
                        VStack(alignment: .leading, spacing: 4) {
                            Text(internship.company)
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                                .accessibilityLabel("Company: \(internship.company)")

                            Text(internship.role)
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Role: \(internship.role)")
                        }

                        // Detail chips
                        VStack(alignment: .leading, spacing: 8) {
                            if let salary = internship.salary, !salary.isEmpty {
                                InternshipDetailRow(icon: "dollarsign.circle.fill", label: "Salary", value: salary, color: .green)
                            }
                            if let location = internship.location, !location.isEmpty {
                                InternshipDetailRow(icon: "mappin.circle.fill", label: "Location", value: location, color: .blue)
                            }
                            if let deadline = internship.deadline, !deadline.isEmpty {
                                InternshipDetailRow(icon: "calendar.badge.clock", label: "Deadline", value: deadline, color: .orange)
                            }
                        }

                        // Description
                        if let description = internship.description, !description.isEmpty {
                            Divider()
                            Text(description)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityLabel("Description: \(description)")
                        }

                        // Footer
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(DateFormatting.formatRelativeTime(internship.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Posted \(DateFormatting.formatRelativeTime(internship.createdAt))")

                            Spacer()

                            HStack(spacing: 5) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.callout)
                                    .foregroundColor(.vibrantTeal)
                                Text("\(internship.comments)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.vibrantTeal)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(internship.comments) comments")
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )

                    Divider().padding(.vertical, 8)

                    // Comments section header with sort
                    HStack {
                        Text("Comments")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)

                        Spacer()

                        if !viewModel.comments.isEmpty {
                            Picker("Sort", selection: $viewModel.selectedSortOrder) {
                                Text(SortOrder.newest.displayName).tag(SortOrder.newest)
                                Text(SortOrder.oldest.displayName).tag(SortOrder.oldest)
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("Sort comments")
                            .onChange(of: viewModel.selectedSortOrder) { _, _ in
                                viewModel.sortOrderChanged(internshipId: internship.id, authState: authState)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    // Comments list
                    commentsList
                }
                .padding()
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

            Divider()

            // Comment input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $viewModel.commentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(viewModel.isSubmitting)
                    .accessibilityLabel("Comment text field")
                    .accessibilityHint("Enter your comment here")

                Button(action: {
                    HapticFeedback.light()
                    viewModel.submitComment(internshipId: internship.id, authState: authState, internship: $internship, onSuccess: {})
                }) {
                    if viewModel.isSubmitting {
                        ProgressView().frame(width: 32, height: 32)
                    } else {
                        ZStack {
                            Circle()
                                .fill(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      ? AnyShapeStyle(Color.gray.opacity(0.3))
                                      : AnyShapeStyle(Color.purplePinkGradient))
                                .frame(width: 36, height: 36)
                            Image(systemName: "arrow.up")
                                .font(.callout.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)
                .accessibilityLabel("Submit comment")
                .accessibilityHint("Double tap to post your comment")
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Internship Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if internship.author.id == authState.currentUser?.id {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Posting", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Posting options")
                }
            }
        }
        .onAppear {
            viewModel.loadComments(internshipId: internship.id, authState: authState)
        }
        .refreshable {
            await viewModel.refreshComments(internshipId: internship.id, authState: authState)
        }
        .confirmationDialog(
            "Delete Posting",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteInternship(internship: internship, authState: authState) {
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this internship posting?")
        }
        .confirmationDialog(
            "Delete Comment",
            isPresented: Binding(
                get: { viewModel.commentToDelete != nil },
                set: { if !$0 { viewModel.commentToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let comment = viewModel.commentToDelete {
                    viewModel.deleteComment(comment, internshipId: internship.id, authState: authState, internship: $internship)
                    viewModel.commentToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { viewModel.commentToDelete = nil }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }

    @ViewBuilder
    private var commentsList: some View {
        if viewModel.isLoadingComments && viewModel.comments.isEmpty {
            HStack {
                Spacer()
                ProgressView("Loading comments...")
                Spacer()
            }
            .padding()
        } else if viewModel.comments.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Be the first to comment!")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("No comments yet. Be the first to comment!")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.comments) { comment in
                    CommentRowView(
                        comment: comment,
                        isOwnComment: comment.author.id == authState.currentUser?.id,
                        onDelete: {
                            viewModel.commentToDelete = comment
                        },
                        onReport: {},
                        onTapAuthor: {
                            onTapAuthor?(comment.author.id, comment.author.profileName)
                        }
                    )
                    .onAppear {
                        viewModel.loadMoreCommentsIfNeeded(for: comment, internshipId: internship.id, authState: authState)
                    }
                }

                if viewModel.isLoadingMoreComments {
                    HStack {
                        Spacer()
                        ProgressView().padding()
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Detail Row
private struct InternshipDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var internship = Internship(
            id: "1",
            company: "Google",
            role: "Software Engineer Intern",
            salary: "$8000/month",
            location: "Mountain View, CA",
            description: "Work on cutting-edge projects with experienced mentors.",
            deadline: "2026-06-30",
            wall: "CAMPUS",
            comments: 2,
            author: Post.Author(id: "user1", profileName: "Recruiter", isAnonymous: false),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        var body: some View {
            NavigationStack {
                InternshipDetailView(internship: $internship)
                    .environmentObject(AuthState())
            }
        }
    }
    return PreviewWrapper()
}
