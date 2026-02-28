//
//  CreatePostViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for CreatePostView - handles post creation business logic
//

import SwiftUI
import PhotosUI

@MainActor
class CreatePostViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var postTitle = ""
    @Published var postContent = ""
    @Published var selectedWall: WallType = .campus
    @Published var isPosting = false
    @Published var errorMessage: String?
    @Published var selectedImages: [UIImage] = []
    @Published var isLoadingImages: Bool = false
    @Published var imageLoadProgress: Double = 0
    
    // MARK: - Dependencies
    private let postService: PostServiceProtocol
    
    // MARK: - Constants
    private let maxTitleCharacters = 255
    private let maxContentCharacters = 5000
    private let maxImages = 5
    
    // MARK: - Initialization
    init(postService: PostServiceProtocol = PostService.shared) {
        self.postService = postService
    }
    
    // MARK: - Computed Properties
    var titleCharacterCount: Int {
        postTitle.count
    }
    
    var contentCharacterCount: Int {
        postContent.count
    }
    
    var isTitleOverLimit: Bool {
        postTitle.count > maxTitleCharacters
    }
    
    var isContentOverLimit: Bool {
        postContent.count > maxContentCharacters
    }
    
    var isPostButtonDisabled: Bool {
        postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        postTitle.count > maxTitleCharacters ||
        postContent.count > maxContentCharacters ||
        isPosting ||
        isLoadingImages
    }
    
    var maxTitleCount: Int {
        maxTitleCharacters
    }
    
    var maxContentCount: Int {
        maxContentCharacters
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

    // MARK: - Photo Loading

    func loadPhotos(_ items: [PhotosPickerItem]) async {
        isLoadingImages = true
        imageLoadProgress = 0

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.imageLoadProgress < 0.9 {
                self.imageLoadProgress += 0.03
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
            errorMessage = "One or more photos are still downloading from iCloud. Please wait a moment and try again."
        } else if hasError {
            errorMessage = "One or more photos could not be loaded"
        }
    }
    
    // MARK: - Public Methods
    func createPost(authState: AuthState, onSuccess: @escaping () -> Void) {
        let trimmedTitle = postTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Post title cannot be empty"
            return
        }
        
        guard trimmedTitle.count <= maxTitleCharacters else {
            errorMessage = "Post title exceeds maximum length of \(maxTitleCharacters) characters"
            return
        }
        
        guard !trimmedContent.isEmpty else {
            errorMessage = "Post content cannot be empty"
            return
        }
        
        guard trimmedContent.count <= maxContentCharacters else {
            errorMessage = "Post content exceeds maximum length of \(maxContentCharacters) characters"
            return
        }
        
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }
        
        isPosting = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await postService.createPost(title: trimmedTitle, content: trimmedContent, wall: selectedWall, images: selectedImages, token: token, userId: userId)
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

// MARK: - Timeout Helpers

struct TimeoutError: Error {}

func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        group.cancelAll()
        return result
    }
}
