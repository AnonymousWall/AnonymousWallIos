//
//  CreatePostViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for CreatePostView - handles post creation business logic
//

import SwiftUI

/// Distinguishes standard text/image posts from poll posts.
enum PostType: String {
    case standard
    case poll
}

@MainActor
class CreatePostViewModel: ImagePickerViewModel {
    // MARK: - Published Properties
    @Published var postTitle = ""
    @Published var postContent = ""
    @Published var selectedWall: WallType = .campus
    @Published var isPosting = false
    @Published var errorMessage: String?
    
    // MARK: - Poll State
    @Published var postType: PostType = .standard
    @Published var pollOptions: [String] = ["", ""]
    
    // MARK: - Dependencies
    private let postService: PostServiceProtocol
    
    // MARK: - Constants
    private let maxTitleCharacters = 255
    private let maxContentCharacters = 5000
    private let maxPollOptionCharacters = 100
    
    // MARK: - Initialization
    init(postService: PostServiceProtocol = PostService.shared) {
        self.postService = postService
        super.init(maxImages: 5)
    }
    
    // MARK: - Computed Properties
    
    var isPollMode: Bool { postType == .poll }
    var canAddPollOption: Bool { pollOptions.count < 4 }
    var canRemovePollOption: Bool { pollOptions.count > 2 }
    
    var arePollOptionsValid: Bool {
        pollOptions.count >= 2 &&
        pollOptions.count <= 4 &&
        pollOptions.allSatisfy {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty && $0.count <= maxPollOptionCharacters
        }
    }
    
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
        let titleEmpty = postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let titleOver = postTitle.count > maxTitleCharacters
        
        if isPollMode {
            let contentOver = postContent.count > maxContentCharacters
            return titleEmpty || titleOver || contentOver || !arePollOptionsValid || isPosting || isLoadingImages
        }
        
        return titleEmpty ||
        postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        titleOver ||
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
    
    var maxPollOptionCount: Int {
        maxPollOptionCharacters
    }
    
    // MARK: - Poll Option Management
    
    func addPollOption() {
        guard canAddPollOption else { return }
        pollOptions.append("")
    }
    
    func removePollOption(at index: Int) {
        guard canRemovePollOption, pollOptions.indices.contains(index) else { return }
        pollOptions.remove(at: index)
    }
    
    // MARK: - Error Reporting
    override func setError(_ message: String) {
        errorMessage = message
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
        
        if !isPollMode {
            guard !trimmedContent.isEmpty else {
                errorMessage = "Post content cannot be empty"
                return
            }
            
            guard trimmedContent.count <= maxContentCharacters else {
                errorMessage = "Post content exceeds maximum length of \(maxContentCharacters) characters"
                return
            }
        }
        
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }
        
        isPosting = true
        errorMessage = nil
        
        if isPollMode {
            let trimmedOptions = pollOptions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            Task {
                do {
                    _ = try await postService.createPollPost(
                        title: trimmedTitle,
                        content: trimmedContent.isEmpty ? nil : trimmedContent,
                        wall: selectedWall,
                        pollOptions: trimmedOptions,
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
        } else {
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
}

