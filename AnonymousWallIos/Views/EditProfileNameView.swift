//
//  EditProfileNameView.swift
//  AnonymousWallIos
//
//  View for editing user's profile name
//

import SwiftUI

struct EditProfileNameView: View {
    @EnvironmentObject var authState: AuthState
    @Environment(\.dismiss) var dismiss
    
    @State private var profileName: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Profile Name", text: $profileName)
                        .autocapitalization(.words)
                        .disabled(isSubmitting)
                } header: {
                    Text("Display Name")
                } footer: {
                    Text("This name will be shown on your posts and comments. Leave empty to use 'Anonymous'.")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateProfileName()
                    }
                    .disabled(isSubmitting)
                }
            }
            .onAppear {
                // Pre-populate with current profile name
                if let currentUser = authState.currentUser {
                    profileName = currentUser.profileName == "Anonymous" ? "" : currentUser.profileName
                }
            }
        }
    }
    
    private func updateProfileName() {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Authentication required"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        // Trim the profile name, empty string will be sent as-is (backend will set to Anonymous)
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let updatedUser = try await AuthService.shared.updateProfileName(
                    profileName: trimmedName,
                    token: token,
                    userId: userId
                )
                
                await MainActor.run {
                    // Update the user in auth state, preserving password status
                    authState.updateUser(updatedUser, preservePasswordStatus: true)
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    if let networkError = error as? NetworkError {
                        errorMessage = networkError.localizedDescription
                    } else {
                        errorMessage = "Failed to update profile name: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

#Preview {
    EditProfileNameView()
        .environmentObject(AuthState())
}
