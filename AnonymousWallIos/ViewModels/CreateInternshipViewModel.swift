//
//  CreateInternshipViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for CreateInternshipView - handles internship creation validation
//

import SwiftUI

@MainActor
class CreateInternshipViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var company = ""
    @Published var role = ""
    @Published var salary = ""
    @Published var location = ""
    @Published var description = ""
    @Published var deadline = ""
    @Published var selectedWall: WallType = .campus
    @Published var isPosting = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let service: InternshipServiceProtocol

    // MARK: - Constants
    let maxCompanyLength = 255
    let maxRoleLength = 255
    let maxDescriptionLength = 5000

    // MARK: - Initialization
    init(service: InternshipServiceProtocol = InternshipService.shared) {
        self.service = service
    }

    // MARK: - Computed Properties
    var isCompanyOverLimit: Bool { company.count > maxCompanyLength }
    var isRoleOverLimit: Bool { role.count > maxRoleLength }
    var isDescriptionOverLimit: Bool { description.count > maxDescriptionLength }

    var isSubmitDisabled: Bool {
        company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        isCompanyOverLimit || isRoleOverLimit || isDescriptionOverLimit ||
        isPosting
    }

    // MARK: - Public Methods
    func createInternship(authState: AuthState, onSuccess: @escaping () -> Void) {
        let trimmedCompany = company.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCompany.isEmpty else {
            errorMessage = "Company cannot be empty"
            return
        }

        guard trimmedCompany.count <= maxCompanyLength else {
            errorMessage = "Company name cannot exceed \(maxCompanyLength) characters"
            return
        }

        guard !trimmedRole.isEmpty else {
            errorMessage = "Role cannot be empty"
            return
        }

        guard trimmedRole.count <= maxRoleLength else {
            errorMessage = "Role cannot exceed \(maxRoleLength) characters"
            return
        }

        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }

        isPosting = true
        errorMessage = nil

        let trimmedSalary = salary.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDeadline = deadline.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                _ = try await service.createInternship(
                    company: trimmedCompany,
                    role: trimmedRole,
                    salary: trimmedSalary.isEmpty ? nil : trimmedSalary,
                    location: trimmedLocation.isEmpty ? nil : trimmedLocation,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    deadline: trimmedDeadline.isEmpty ? nil : trimmedDeadline,
                    wall: selectedWall,
                    token: token,
                    userId: userId
                )
                HapticFeedback.success()
                isPosting = false
                onSuccess()
            } catch {
                isPosting = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
