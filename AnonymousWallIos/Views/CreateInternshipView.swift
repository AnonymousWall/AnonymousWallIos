//
//  CreateInternshipView.swift
//  AnonymousWallIos
//
//  View for creating a new internship posting
//

import SwiftUI

struct CreateInternshipView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateInternshipViewModel()

    var onCreated: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Wall selection
                    WallPickerSection(selectedWall: $viewModel.selectedWall)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // Required fields
                    requiredFieldsSection

                    // Optional fields
                    optionalFieldsSection

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        FormErrorMessage(message: errorMessage)
                            .padding(.horizontal)
                    }

                    // Submit button
                    CreateFormSubmitButton(
                        icon: "paperplane.fill",
                        label: "Post Internship",
                        isLoading: viewModel.isPosting,
                        isDisabled: viewModel.isSubmitDisabled,
                        gradient: Color.tealPurpleGradient,
                        action: {
                            HapticFeedback.light()
                            viewModel.createInternship(authState: authState) {
                                onCreated()
                                dismiss()
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .accessibilityLabel("Submit internship posting")
                    .accessibilityHint(viewModel.isSubmitDisabled
                        ? "Complete required fields to post"
                        : "Double tap to create your posting")
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Internship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Double tap to cancel creating a posting")
                }
            }
        }
    }

    @ViewBuilder
    private var requiredFieldsSection: some View {
        FormSectionCard(title: "Required", systemIcon: "asterisk.circle.fill") {
            StyledTextField(
                icon: "building.2",
                label: "Company",
                placeholder: "e.g. Google",
                text: $viewModel.company,
                characterLimit: viewModel.maxCompanyLength,
                accessibilityLabel: "Company name",
                accessibilityHint: "Required. Enter the company name"
            )

            StyledTextField(
                icon: "person.text.rectangle",
                label: "Role",
                placeholder: "e.g. Software Engineer Intern",
                text: $viewModel.role,
                characterLimit: viewModel.maxRoleLength,
                accessibilityLabel: "Role",
                accessibilityHint: "Required. Enter the internship role"
            )
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var optionalFieldsSection: some View {
        FormSectionCard(title: "Optional Details", systemIcon: "list.bullet.rectangle") {
            StyledTextField(
                icon: "banknote",
                label: "Salary",
                placeholder: "e.g. $8000/month",
                text: $viewModel.salary,
                accessibilityLabel: "Salary"
            )

            StyledTextField(
                icon: "mappin.and.ellipse",
                label: "Location",
                placeholder: "e.g. Mountain View, CA",
                text: $viewModel.location,
                accessibilityLabel: "Location"
            )

            StyledTextField(
                icon: "calendar.badge.clock",
                label: "Application Deadline",
                placeholder: "e.g. 2026-06-30",
                text: $viewModel.deadline,
                accessibilityLabel: "Application deadline"
            )

            StyledTextEditorField(
                icon: "text.alignleft",
                label: "Description",
                placeholder: "Describe the internship opportunity…",
                text: $viewModel.description,
                characterLimit: viewModel.maxDescriptionLength,
                minHeight: 120,
                accessibilityLabel: "Description"
            )
        }
        .padding(.horizontal)
    }
}

#Preview {
    CreateInternshipView(onCreated: {})
        .environmentObject(AuthState())
}
