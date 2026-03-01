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

    // Set to true when the user taps "View Results" or casts a vote.
    // Used to trigger a silent background re-fetch after pull-to-refresh
    // delivers vote-count-free list data so percentages stay fresh.
    private(set) var userViewedResults = false

    // Holds the latest background re-fetch task so it can be cancelled when
    // a new refresh arrives or the ViewModel is deallocated.
    private var backgroundRefetchTask: Task<Void, Never>?

    private let postService: PostServiceProtocol
    
    init(poll: PollDTO? = nil, postService: PostServiceProtocol = PostService.shared) {
        self.poll = poll
        self.postService = postService
    }

    deinit {
        backgroundRefetchTask?.cancel()
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
            userViewedResults = true
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
        userViewedResults = true
        await loadResults(postId: postId, viewResults: true, authState: authState)
    }
    
    // MARK: - Sync from parent
    
    /// Syncs fresh poll data from the parent post (e.g. after a list refresh).
    /// Skipped while a vote is in flight to preserve optimistic UI state.
    /// When local state already shows results (user has voted this session),
    /// a stale server snapshot that has resultsVisible: false is NOT allowed
    /// to clobber the local voted state — only totalVotes is updated so that
    /// votes from other users are still reflected.
    /// When `userViewedResults` is true and the incoming snapshot carries no
    /// vote counts (list endpoint omits them for non-voters), a silent
    /// background re-fetch with viewResults=true is fired so that option
    /// percentages stay fresh without blocking the UI.
    func updatePoll(_ incoming: PollDTO, postId: UUID? = nil, authState: AuthState? = nil) {
        guard !isVoting else { return }

        if let current = poll, current.resultsVisible && !incoming.resultsVisible {
            // Local state is ahead of the server list snapshot (user voted in
            // this session but the list endpoint still returns pre-vote data).
            // Prefer incoming options when they carry actual vote counts (richer
            // data); otherwise keep the locally-voted options so percentages
            // remain visible. Always take the higher totalVotes so that
            // (a) our own vote is never subtracted and
            // (b) concurrent votes by other users are still reflected.
            let options = incoming.options.first?.voteCount != nil ? incoming.options : current.options
            poll = PollDTO(
                options: options,
                totalVotes: max(current.totalVotes, incoming.totalVotes),
                userVotedOptionId: current.userVotedOptionId,
                resultsVisible: current.resultsVisible
            )
            // The list endpoint never sends voteCount for non-voters, so
            // stale 0% percentages can linger after other users have voted.
            // When the user already explicitly viewed results this session,
            // re-fetch silently to refresh the percentages.
            if userViewedResults,
               !incoming.options.isEmpty,
               incoming.options.first?.voteCount == nil,
               let postId, let authState {
                backgroundRefetchTask?.cancel()
                backgroundRefetchTask = Task {
                    await loadResults(postId: postId, viewResults: true, silent: true, authState: authState)
                }
            }
            return
        }

        poll = incoming
    }
    
    // MARK: - Private Helpers
    
    private func loadResults(postId: UUID, viewResults: Bool, silent: Bool = false, authState: AuthState) async {
        guard let token = authState.authToken,
              let userId = authState.currentUser?.id else { return }
        
        if viewResults && !silent {
            isLoadingResults = true
        }
        
        do {
            let updatedPoll = try await postService.getPoll(postId: postId, viewResults: viewResults, token: token, userId: userId)
            poll = updatedPoll
        } catch {
            if viewResults && !silent {
                errorMessage = error.localizedDescription
            }
        }
        
        if !silent {
            isLoadingResults = false
        }
    }
}
