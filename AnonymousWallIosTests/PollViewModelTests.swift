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
    // MARK: - Unauthenticated

    @Test func testVoteWithoutAuthSetsError() async {
        let vm = PollViewModel(poll: makePoll())
        let unauthState = AuthState(loadPersistedState: false)

        await vm.vote(postId: UUID(), optionId: UUID(), authState: unauthState)

        #expect(vm.errorMessage == "Not authenticated")
        #expect(vm.isVoting == false)
    }
}
