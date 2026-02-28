//
//  PollCardView.swift
//  AnonymousWallIos
//
//  Displays a poll inside a post card.
//  Shows options sorted by displayOrder.
//  Before voting or viewing results the progress bars and counts are hidden.
//  After voting or tapping "View Results" the results become visible.
//

import SwiftUI

struct PollCardView: View {
    let postId: UUID
    @StateObject private var pollViewModel: PollViewModel
    @EnvironmentObject var authState: AuthState

    init(postId: UUID, poll: PollDTO) {
        self.postId = postId
        _pollViewModel = StateObject(wrappedValue: PollViewModel(poll: poll))
    }

    private var currentPoll: PollDTO? { pollViewModel.poll }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let poll = currentPoll {
                let sortedOptions = poll.options.sorted { $0.displayOrder < $1.displayOrder }

                ForEach(sortedOptions) { option in
                    PollOptionRow(
                        option: option,
                        isVoted: poll.userVotedOptionId == option.id,
                        resultsVisible: poll.resultsVisible,
                        isVoting: pollViewModel.isVoting,
                        isLoadingResults: pollViewModel.isLoadingResults,
                        isThisOptionVoting: pollViewModel.votingOptionId == option.id
                    ) {
                        Task {
                            await pollViewModel.vote(postId: postId, optionId: option.id, authState: authState)
                        }
                    }
                }

                // Footer
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(poll.totalVotes) \(poll.totalVotes == 1 ? "vote" : "votes")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("\(poll.totalVotes) votes")

                    if !poll.resultsVisible && !pollViewModel.isLoadingResults {
                        Spacer()
                        Button {
                            Task {
                                await pollViewModel.loadResults(postId: postId, authState: authState)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if pollViewModel.isLoadingResults {
                                    ProgressView().controlSize(.mini)
                                } else {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.caption2)
                                    Text("View Results")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            .foregroundColor(.primaryPurple)
                        }
                        .disabled(pollViewModel.isLoadingResults)
                        .accessibilityLabel("View poll results")
                        .accessibilityHint("Double tap to reveal vote counts and percentages")
                    }
                }
                .padding(.top, 4)

                if let error = pollViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                        .accessibilityLabel("Error: \(error)")
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
    }
}

// MARK: - Individual Option Row

private struct PollOptionRow: View {
    let option: PollOptionDTO
    let isVoted: Bool
    let resultsVisible: Bool
    let isVoting: Bool
    let isLoadingResults: Bool
    let isThisOptionVoting: Bool
    let onVote: () -> Void

    private var progressFraction: Double {
        guard resultsVisible, let pct = option.percentage else { return 0 }
        return max(0, min(pct / 100.0, 1.0))
    }

    private var formattedPercentage: String? {
        guard resultsVisible, let pct = option.percentage else { return nil }
        return "\(Int(pct.rounded()))%"
    }

    var body: some View {
        Button(action: {
            guard !isVoting && !isLoadingResults else { return }
            onVote()
        }) {
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 42)

                // Fill bar (only visible when results are available)
                if resultsVisible {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isVoted ? Color.primaryPurple.opacity(0.25) : Color.primaryPurple.opacity(0.12))
                            .frame(width: geo.size.width * progressFraction, height: 42)
                            .animation(.easeInOut(duration: 0.4), value: progressFraction)
                    }
                    .frame(height: 42)
                }

                HStack(spacing: 8) {
                    // Option text
                    Text(option.optionText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer()

                    if isThisOptionVoting {
                        ProgressView().controlSize(.mini)
                    } else if isVoted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.primaryPurple)
                            .font(.callout)
                            .accessibilityHidden(true)
                    }

                    if let pct = formattedPercentage {
                        Text(pct)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(isVoted ? .primaryPurple : .secondary)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 42)
            }
        }
        .disabled(isVoting || isLoadingResults)
        .buttonStyle(.plain)
        .accessibilityLabel(option.optionText + (isVoted ? ", your choice" : ""))
        .accessibilityHint(isVoted ? "You voted for this option" : "Double tap to vote for this option")
        .accessibilityValue(formattedPercentage.map { "\($0)" } ?? "")
    }
}
