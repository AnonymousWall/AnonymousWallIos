//
//  ImagePickerViewModel.swift
//  AnonymousWallIos
//
//  Base class that provides shared image picking, loading, and iCloud timeout
//  handling for creation-flow ViewModels.
//

import SwiftUI
import PhotosUI

@MainActor
class ImagePickerViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var selectedImages: [UIImage] = []
    @Published var isLoadingImages: Bool = false
    @Published var imageLoadProgress: Double = 0

    // MARK: - Constants
    let maxImages: Int

    // MARK: - Initialization
    init(maxImages: Int = 5) {
        self.maxImages = maxImages
    }

    // MARK: - Computed Properties
    var canAddMoreImages: Bool { selectedImages.count < maxImages }
    var imageCount: Int { selectedImages.count }
    var remainingImageSlots: Int { maxImages - selectedImages.count }

    // MARK: - Image Management
    func addImage(_ image: UIImage) {
        guard selectedImages.count < maxImages else {
            setError("Maximum \(maxImages) images allowed")
            return
        }
        selectedImages.append(image)
    }

    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }

    // MARK: - Photo Loading
    func loadPhotos(_ items: [PhotosPickerItem]) async {
        isLoadingImages = true
        imageLoadProgress = 0

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.imageLoadProgress < 0.9 {
                    self.imageLoadProgress += 0.03
                }
            }
        }

        defer {
            timer.invalidate()
            imageLoadProgress = 1.0
            isLoadingImages = false
        }

        var hasTimeout = false
        var hasError = false

        for item in items {
            do {
                let data = try await withTimeout(seconds: 30) {
                    try await item.loadTransferable(type: Data.self)
                }
                if let data, let image = UIImage(data: data) {
                    addImage(image)
                }
            } catch is TimeoutError {
                hasTimeout = true
            } catch {
                hasError = true
            }
        }

        if hasTimeout {
            setError("One or more photos are still downloading from iCloud. Please wait a moment and try again.")
        } else if hasError {
            setError("One or more photos could not be loaded")
        }
    }

    // MARK: - Error Reporting
    /// Subclasses override this to write to their own `errorMessage` property.
    /// A debug assertion fires if a subclass forgets to override.
    func setError(_ message: String) {
        assertionFailure("setError(_:) must be overridden by subclasses of ImagePickerViewModel")
    }
}
