//
//  PollViewModel.swift
//  AnonymousWallIos
//
//  ViewModel for voting on and loading poll results
//

import Foundation

@MainActor
class PollViewModel: ObservableObject {
    @Published var poll: PollDTO?
    @Published var isVoting: Bool = false
    @Published var isLoadingResults: Bool = false
    @Published var errorMessage: String?
    
    // Track which option is being voted on to show per-option loading
    @Published var votingOptionId: UUID?
    
    private let postService: PostServiceProtocol
    
    init(poll: PollDTO? = nil, postService: PostServiceProtocol = PostService.shared) {
        self.poll = poll
        self.postService = postService
    }
    
    // MARK: - Vote
    
    /// Vote for an option. On 409 (already voted) silently refreshes poll state.
    func vote(postId: UUID, optionId: UUID, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else {
            errorMessage = "Not authenticated"
            return
        }
        
        isVoting = true
        votingOptionId = optionId
        errorMessage = nil
        
        do {
            let updatedPoll = try await postService.votePoll(postId: postId, optionId: optionId, token: token, userId: userId)
            poll = updatedPoll
        } catch NetworkError.conflict {
            // User already voted — silently refresh without showing error
            await loadResults(postId: postId, viewResults: false, authState: authState)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isVoting = false
        votingOptionId = nil
    }
    
    // MARK: - Load Results
    
    /// Load poll results with viewResults=true (shows vote counts and percentages).
    func loadResults(postId: UUID, authState: AuthState) async {
        await loadResults(postId: postId, viewResults: true, authState: authState)
    }
    
    // MARK: - Sync from parent
    
    /// Syncs fresh poll data from the parent post (e.g. after a list refresh).
    /// Skipped while a vote is in flight to preserve optimistic UI state.
    func updatePoll(_ freshPoll: PollDTO) {
        guard !isVoting else { return }
        poll = freshPoll
    }
    
    // MARK: - Private Helpers
    
    private func loadResults(postId: UUID, viewResults: Bool, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }
        
        if viewResults {
            isLoadingResults = true
        }
        
        do {
            let updatedPoll = try await postService.getPoll(postId: postId, viewResults: viewResults, token: token, userId: userId)
            poll = updatedPoll
        } catch {
            if viewResults {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoadingResults = false
    }
}
