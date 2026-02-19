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

                    // Required fields
                    requiredFieldsSection

                    // Optional fields
                    optionalFieldsSection

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 0)

                    // Submit button
                    Button(action: {
                        HapticFeedback.light()
                        viewModel.createInternship(authState: authState) {
                            onCreated()
                            dismiss()
                        }
                    }) {
                        if viewModel.isPosting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "paperplane.fill").font(.body)
                                Text("Post Internship").fontWeight(.bold).font(.body)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 56)
                    .background(
                        viewModel.isSubmitDisabled
                        ? AnyShapeStyle(Color.gray)
                        : AnyShapeStyle(Color.purplePinkGradient)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: viewModel.isSubmitDisabled ? Color.clear : Color.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .disabled(viewModel.isSubmitDisabled)
                    .accessibilityLabel("Submit internship posting")
                    .accessibilityHint(viewModel.isSubmitDisabled ? "Complete required fields to post" : "Double tap to create your posting")
                }
            }
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Required")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            // Company
            VStack(alignment: .leading, spacing: 6) {
                Text("Company")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                TextField("e.g. Google", text: $viewModel.company)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityLabel("Company name")
                    .accessibilityHint("Required. Enter the company name")
                HStack {
                    Spacer()
                    Text("\(viewModel.company.count)/\(viewModel.maxCompanyLength)")
                        .font(.caption)
                        .foregroundColor(viewModel.isCompanyOverLimit ? .red : .gray)
                }
                .padding(.horizontal)
            }

            // Role
            VStack(alignment: .leading, spacing: 6) {
                Text("Role")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                TextField("e.g. Software Engineer Intern", text: $viewModel.role)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityLabel("Role")
                    .accessibilityHint("Required. Enter the internship role")
                HStack {
                    Spacer()
                    Text("\(viewModel.role.count)/\(viewModel.maxRoleLength)")
                        .font(.caption)
                        .foregroundColor(viewModel.isRoleOverLimit ? .red : .gray)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var optionalFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optional")
                .font(.headline)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            // Salary
            VStack(alignment: .leading, spacing: 6) {
                Text("Salary")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                TextField("e.g. $8000/month", text: $viewModel.salary)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityLabel("Salary")
            }

            // Location
            VStack(alignment: .leading, spacing: 6) {
                Text("Location")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                TextField("e.g. Mountain View, CA", text: $viewModel.location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityLabel("Location")
            }

            // Application Deadline
            VStack(alignment: .leading, spacing: 6) {
                Text("Application Deadline")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                TextField("e.g. 2026-06-30", text: $viewModel.deadline)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .accessibilityLabel("Application deadline")
            }

            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.subheadline).fontWeight(.medium)
                    .padding(.horizontal)
                HStack {
                    Spacer()
                    Text("\(viewModel.description.count)/\(viewModel.maxDescriptionLength)")
                        .font(.caption)
                        .foregroundColor(viewModel.isDescriptionOverLimit ? .red : .gray)
                }
                .padding(.horizontal)
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .accessibilityLabel("Description")
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    CreateInternshipView(onCreated: {})
        .environmentObject(AuthState())
}
