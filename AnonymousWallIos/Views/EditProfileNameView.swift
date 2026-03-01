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
    @StateObject private var viewModel: EditProfileNameViewModel
    
    init(userService: UserServiceProtocol = UserService.shared) {
        _viewModel = StateObject(wrappedValue: EditProfileNameViewModel(userService: userService))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Profile Name", text: $viewModel.profileName)
                        .autocapitalization(.words)
                        .disabled(viewModel.isSubmitting)
                } header: {
                    Text("Display Name")
                } footer: {
                    Text("This name will be shown on your posts and comments. Leave empty to use 'Anonymous'.")
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.accentRed)
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
                    .disabled(viewModel.isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateProfileName(authState: authState, onSuccess: { dismiss() })
                    }
                    .disabled(viewModel.isSubmitting)
                }
            }
            .onAppear {
                viewModel.loadCurrentProfileName(from: authState.currentUser)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

#Preview {
    EditProfileNameView()
        .environmentObject(AuthState())
}
