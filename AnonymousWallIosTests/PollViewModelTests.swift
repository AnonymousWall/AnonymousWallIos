//
//  PollViewModelTests.swift
//  AnonymousWallIosTests
//
//  Tests for PollViewModel - voting and result loading logic
//

import Testing
@testable import AnonymousWallIos

@MainActor
struct PollViewModelTests {

    // MARK: - Helpers

    private func makeOption(
        id: UUID = UUID(),
        text: String = "Option",
        order: Int = 0,
        voteCount: Int? = nil,
        percentage: Double? = nil
    ) -> PollOptionDTO {
        PollOptionDTO(id: id, optionText: text, displayOrder: order, voteCount: voteCount, percentage: percentage)
    }

    private func makePoll(
        options: [PollOptionDTO] = [],
        totalVotes: Int = 0,
        userVotedOptionId: UUID? = nil,
        resultsVisible: Bool = false
    ) -> PollDTO {
        PollDTO(options: options, totalVotes: totalVotes, userVotedOptionId: userVotedOptionId, resultsVisible: resultsVisible)
    }

    private func makeAuthState() -> AuthState {
        let state = AuthState(loadPersistedState: false)
        state.authToken = "test-token"
        state.currentUser = User(
            id: "user-1",
            email: "user@test.com",
            profileName: "Test",
            isVerified: true,
            passwordSet: true,
            createdAt: "2026-01-01T00:00:00Z"
        )
        return state
    }

    // MARK: - Initialization

    @Test func testInitializationWithPoll() {
        let poll = makePoll(totalVotes: 5)
        let vm = PollViewModel(poll: poll)
        #expect(vm.poll?.totalVotes == 5)
        #expect(vm.isVoting == false)
        #expect(vm.isLoadingResults == false)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Vote Success

    @Test func testVoteSuccessUpdatesPoll() async {
        let mockService = MockPostService()
        let optionId = UUID()
        let resultPoll = makePoll(totalVotes: 1, userVotedOptionId: optionId, resultsVisible: true)
        mockService.mockPollDTO = resultPoll

        let vm = PollViewModel(poll: makePoll(), postService: mockService)
        let postId = UUID()
        let authState = makeAuthState()

        await vm.vote(postId: postId, optionId: optionId, authState: authState)

        #expect(mockService.votePollCalled == true)
        #expect(vm.poll?.userVotedOptionId == optionId)
        #expect(vm.isVoting == false)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Vote Conflict (409)

    @Test func testVoteConflictSilentlyRefreshesPoll() async {
        let mockService = MockPostService()
        // votePoll will throw a 409 conflict
        mockService.votePollBehavior = .failure(NetworkError.conflict("already voted"))
        // getPoll will return updated poll
        let refreshedPoll = makePoll(totalVotes: 3, resultsVisible: false)
        mockService.mockPollDTO = refreshedPoll
        mockService.getPollBehavior = .success

        let vm = PollViewModel(poll: makePoll(), postService: mockService)
        let authState = makeAuthState()

        await vm.vote(postId: UUID(), optionId: UUID(), authState: authState)

        #expect(mockService.votePollCalled == true)
        #expect(mockService.getPollCalled == true)
        // No error shown
        #expect(vm.errorMessage == nil)
        #expect(vm.isVoting == false)
    }

    // MARK: - Vote Network Error

    @Test func testVoteNetworkErrorSetsErrorMessage() async {
        let mockService = MockPostService()
        mockService.votePollBehavior = .failure(NetworkError.noConnection)

        let vm = PollViewModel(poll: makePoll(), postService: mockService)
        let authState = makeAuthState()

        await vm.vote(postId: UUID(), optionId: UUID(), authState: authState)

        #expect(vm.errorMessage != nil)
        #expect(vm.isVoting == false)
    }

    // MARK: - Load Results

    @Test func testLoadResultsUpdatesPoll() async {
        let mockService = MockPostService()
        let resultPoll = makePoll(totalVotes: 10, resultsVisible: true)
        mockService.mockPollDTO = resultPoll

        let vm = PollViewModel(poll: makePoll(), postService: mockService)
        let authState = makeAuthState()

        await vm.loadResults(postId: UUID(), authState: authState)

        #expect(mockService.getPollCalled == true)
        #expect(vm.poll?.resultsVisible == true)
        #expect(vm.isLoadingResults == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func testLoadResultsFailureSetsErrorMessage() async {
        let mockService = MockPostService()
        mockService.getPollBehavior = .failure(NetworkError.noConnection)

        let vm = PollViewModel(poll: makePoll(), postService: mockService)
        let authState = makeAuthState()

        await vm.loadResults(postId: UUID(), authState: authState)

        #expect(vm.errorMessage != nil)
        #expect(vm.isLoadingResults == false)
    }

    // MARK: - updatePoll merge logic

    @Test func testUpdatePollReplacesWhenNoLocalState() {
        let vm = PollViewModel(poll: nil)
        let incoming = makePoll(totalVotes: 5, resultsVisible: false)
        vm.updatePoll(incoming)
        #expect(vm.poll?.totalVotes == 5)
    }

    @Test func testUpdatePollReplacesWhenLocalNotResultsVisible() {
        let vm = PollViewModel(poll: makePoll(totalVotes: 0, resultsVisible: false))
        let incoming = makePoll(totalVotes: 3, resultsVisible: false)
        vm.updatePoll(incoming)
        #expect(vm.poll?.totalVotes == 3)
    }

    @Test func testUpdatePollPreservesLocalVotedStateWhenServerSnapshotIsStale() {
        // After UserA votes, local poll has resultsVisible: true with options/percentages.
        // A pull-to-refresh brings back the list-endpoint snapshot which still has
        // resultsVisible: false. updatePoll must NOT overwrite local voted state.
        let optionId = UUID()
        let votedOption = makeOption(id: optionId, text: "A", voteCount: 1, percentage: 100)
        let localPoll = makePoll(options: [votedOption], totalVotes: 1, userVotedOptionId: optionId, resultsVisible: true)
        let vm = PollViewModel(poll: localPoll)

        // Server list snapshot: pre-vote, resultsVisible: false, but totalVotes updated (2 from another voter)
        let staleServerPoll = makePoll(totalVotes: 2, resultsVisible: false)
        vm.updatePoll(staleServerPoll)

        // resultsVisible and userVotedOptionId must be preserved
        #expect(vm.poll?.resultsVisible == true)
        #expect(vm.poll?.userVotedOptionId == optionId)
        // totalVotes takes max(local=1, server=2) = 2
        #expect(vm.poll?.totalVotes == 2)
        // Options (with percentages) must be preserved from local voted state
        #expect(vm.poll?.options.first?.percentage == 100)
    }

    @Test func testUpdatePollDoesNotResetVoteCountWhenServerSnapshotIsStillAtZero() {
        // Regression: UserA votes (totalVotes becomes 1 locally), then pulls to refresh.
        // The list endpoint hasn't reflected the vote yet and returns totalVotes: 0.
        // The vote count must NOT go backwards to 0.
        let optionId = UUID()
        let localPoll = makePoll(totalVotes: 1, userVotedOptionId: optionId, resultsVisible: true)
        let vm = PollViewModel(poll: localPoll)

        // Server list snapshot still has old totalVotes (0) and resultsVisible: false
        let staleServerPoll = makePoll(totalVotes: 0, resultsVisible: false)
        vm.updatePoll(staleServerPoll)

        // totalVotes must NOT reset — takes max(local=1, server=0) = 1
        #expect(vm.poll?.totalVotes == 1)
        // Voted state preserved
        #expect(vm.poll?.resultsVisible == true)
        #expect(vm.poll?.userVotedOptionId == optionId)
    }

    @Test func testUpdatePollAcceptsServerDataWhenBothResultsVisible() {
        // If the server also returns resultsVisible: true (e.g. user voted in another
        // session), the fresh server data should fully replace local state.
        let optionId = UUID()
        let localPoll = makePoll(totalVotes: 1, userVotedOptionId: optionId, resultsVisible: true)
        let vm = PollViewModel(poll: localPoll)

        let serverPoll = makePoll(totalVotes: 5, userVotedOptionId: optionId, resultsVisible: true)
        vm.updatePoll(serverPoll)

        #expect(vm.poll?.totalVotes == 5)
        #expect(vm.poll?.resultsVisible == true)
    }

    @Test func testUpdatePollUsesIncomingOptionsWhenTheyCarryVoteData() {
        // If the server snapshot (resultsVisible: false in the list) contains options
        // that have voteCount populated (e.g. from a personalised endpoint), those
        // fresher options must be preferred over the locally-cached ones.
        let optionId = UUID()
        let localOption = makeOption(id: optionId, text: "A", voteCount: 1, percentage: 100)
        let localPoll = makePoll(options: [localOption], totalVotes: 1, userVotedOptionId: optionId, resultsVisible: true)
        let vm = PollViewModel(poll: localPoll)

        // Incoming: resultsVisible false but options still carry voteCount (richer data)
        let freshOption = makeOption(id: optionId, text: "A", voteCount: 3, percentage: 75)
        let incomingPoll = makePoll(options: [freshOption], totalVotes: 4, resultsVisible: false)
        vm.updatePoll(incomingPoll)

        // Incoming options must be used because they have voteCount data
        #expect(vm.poll?.options.first?.voteCount == 3)
        #expect(vm.poll?.options.first?.percentage == 75)
        // totalVotes takes max(local=1, server=4) = 4
        #expect(vm.poll?.totalVotes == 4)
        // Voted state preserved
        #expect(vm.poll?.resultsVisible == true)
        #expect(vm.poll?.userVotedOptionId == optionId)
    }

    @Test func testUpdatePollSkippedWhileVoting() async {
        let mockService = MockPostService()
        // Keep vote in-flight long enough to call updatePoll concurrently
        mockService.mockPollDTO = makePoll(totalVotes: 1, resultsVisible: true)

        let vm = PollViewModel(poll: makePoll(totalVotes: 0), postService: mockService)
        let authState = makeAuthState()

        // Simulate: vote starts (sets isVoting = true), then updatePoll is called
        vm.isVoting = true
        let incoming = makePoll(totalVotes: 99, resultsVisible: false)
        vm.updatePoll(incoming)

        // Update must be skipped while isVoting
        #expect(vm.poll?.totalVotes == 0)
        vm.isVoting = false
    }

    // MARK: - userViewedResults flag

    @Test func testUserViewedResultsSetAfterLoadResults() async {
        let mockService = MockPostService()
        mockService.mockPollDTO = makePoll(totalVotes: 3, resultsVisible: true)

        let vm = PollViewModel(poll: makePoll(), postService: mockService)
        #expect(vm.userViewedResults == false)

        await vm.loadResults(postId: UUID(), authState: makeAuthState())

        #expect(vm.userViewedResults == true)
    }

    @Test func testUserViewedResultsSetAfterSuccessfulVote() async {
        let mockService = MockPostService()
        let optionId = UUID()
        mockService.mockPollDTO = makePoll(totalVotes: 1, userVotedOptionId: optionId, resultsVisible: true)

        let vm = PollViewModel(poll: makePoll(), postService: mockService)
        #expect(vm.userViewedResults == false)

        await vm.vote(postId: UUID(), optionId: optionId, authState: makeAuthState())

        #expect(vm.userViewedResults == true)
    }

    @Test func testUpdatePollTriggersBackgroundRefetchWhenUserViewedResults() async {
        // Scenario: UserB taps "View Results" (resultsVisible=true, 0 votes),
        // then UserA votes on the server. UserB pulls to refresh — the list
        // endpoint returns resultsVisible=false and voteCount=nil. The ViewModel
        // must silently re-call getPoll(viewResults:true) to fetch fresh
        // percentages.
        let mockService = MockPostService()
        // Step 1: simulate user tapping "View Results" — sets userViewedResults=true
        let initialOption = makeOption(text: "A", voteCount: 0, percentage: 0.0)
        mockService.mockPollDTO = makePoll(options: [initialOption], totalVotes: 0, resultsVisible: true)
        let vm = PollViewModel(poll: makePoll(), postService: mockService)
        let postId = UUID()
        await vm.loadResults(postId: postId, authState: makeAuthState())
        #expect(vm.userViewedResults == true)

        // Step 2: reset tracking, then simulate pull-to-refresh delivering stale list data
        mockService.resetCallTracking()
        let updatedOption = makeOption(text: "A", voteCount: 1, percentage: 100.0)
        mockService.mockPollDTO = makePoll(options: [updatedOption], totalVotes: 1, resultsVisible: true)

        let staleFreshOption = makeOption(text: "A")     // voteCount: nil (list endpoint)
        let stalePoll = makePoll(options: [staleFreshOption], totalVotes: 1, resultsVisible: false)
        vm.updatePoll(stalePoll, postId: postId, authState: makeAuthState())

        // Poll until the background task completes (up to 500ms)
        for _ in 0..<50 {
            if mockService.getPollCalled { break }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms increments
        }

        // Background getPoll should have been called with viewResults=true
        #expect(mockService.getPollCalled == true)
        #expect(mockService.getPollLastViewResults == true)
        // Poll should now reflect the fresh percentages
        #expect(vm.poll?.options.first?.percentage == 100.0)
        #expect(vm.poll?.totalVotes == 1)
    }

    @Test func testUpdatePollDoesNotRefetchWhenUserHasNotViewedResults() {
        // No re-fetch should be triggered when user never tapped View Results
        let mockService = MockPostService()
        let localPoll = makePoll(totalVotes: 0, resultsVisible: true)
        let vm = PollViewModel(poll: localPoll, postService: mockService)
        // userViewedResults is false by default

        let stalePoll = makePoll(totalVotes: 1, resultsVisible: false)
        vm.updatePoll(stalePoll, postId: UUID(), authState: makeAuthState())

        #expect(mockService.getPollCalled == false)
    }

    // MARK: - Unauthenticated

    @Test func testVoteWithoutAuthSetsError() async {
        let vm = PollViewModel(poll: makePoll())
        let unauthState = AuthState(loadPersistedState: false)

        await vm.vote(postId: UUID(), optionId: UUID(), authState: unauthState)

        #expect(vm.errorMessage == "Not authenticated")
        #expect(vm.isVoting == false)
    }
}
