//
//  CreateMarketplaceViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for CreateMarketplaceView - handles marketplace item creation
//

import SwiftUI

@MainActor
class CreateMarketplaceViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var title = ""
    @Published var priceText = ""
    @Published var description = ""
    @Published var selectedCategory: MarketplaceCategory?
    @Published var selectedCondition: String = ""
    @Published var selectedWall: WallType = .campus
    @Published var isPosting = false
    @Published var errorMessage: String?
    @Published var selectedImages: [UIImage] = []

    // MARK: - Dependencies
    private let service: MarketplaceServiceProtocol

    // MARK: - Constants
    let maxTitleLength = 255
    let maxDescriptionLength = 5000
    let validConditions = ["new", "like-new", "good", "fair"]
    let conditionDisplayNames = ["New", "Like New", "Good", "Fair"]
    private let maxImages = 5

    // MARK: - Initialization
    init(service: MarketplaceServiceProtocol = MarketplaceService.shared) {
        self.service = service
    }

    // MARK: - Computed Properties
    var isTitleOverLimit: Bool { title.count > maxTitleLength }
    var isDescriptionOverLimit: Bool { description.count > maxDescriptionLength }

    var parsedPrice: Double? {
        Double(priceText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var isPriceValid: Bool {
        guard let price = parsedPrice else { return false }
        return price >= 0 && price <= 99_999_999.99
    }

    var isSubmitDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !isPriceValid ||
        isTitleOverLimit || isDescriptionOverLimit ||
        isPosting
    }

    var canAddMoreImages: Bool { selectedImages.count < maxImages }
    var imageCount: Int { selectedImages.count }
    var remainingImageSlots: Int { maxImages - selectedImages.count }

    // MARK: - Image Management

    func addImage(_ image: UIImage) {
        guard selectedImages.count < maxImages else {
            errorMessage = "Maximum \(maxImages) images allowed"
            return
        }
        selectedImages.append(image)
    }

    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }

    // MARK: - Public Methods
    func createItem(authState: AuthState, onSuccess: @escaping () -> Void) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title cannot be empty"
            return
        }

        guard trimmedTitle.count <= maxTitleLength else {
            errorMessage = "Title cannot exceed \(maxTitleLength) characters"
            return
        }

        guard let price = parsedPrice, price >= 0 else {
            errorMessage = "Please enter a valid price (0 or greater)"
            return
        }

        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }

        isPosting = true
        errorMessage = nil

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryValue = selectedCategory?.rawValue
        let conditionValue = selectedCondition.isEmpty ? nil : selectedCondition
        let imagesToUpload = selectedImages

        Task {
            do {
                _ = try await service.createItem(
                    title: trimmedTitle,
                    price: price,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    category: categoryValue,
                    condition: conditionValue,
                    wall: selectedWall,
                    images: imagesToUpload,
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
