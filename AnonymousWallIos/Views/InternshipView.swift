//
//  InternshipView.swift
//  AnonymousWallIos
//
//  Internship feed view - campus and national walls
//

import SwiftUI

struct InternshipView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var blockViewModel: BlockViewModel
    @ObservedObject var coordinator: InternshipCoordinator
    @StateObject private var campusViewModel = InternshipFeedViewModel(wallType: .campus)
    @StateObject private var nationalViewModel = InternshipFeedViewModel(wallType: .national)
    @State private var selectedWall: WallType = .campus
    @State private var showCreateInternship = false
    @State private var showWallPicker = false

    private var activeViewModel: InternshipFeedViewModel {
        selectedWall == .campus ? campusViewModel : nationalViewModel
    }

    private let minimumScrollableHeight: CGFloat = 300

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            VStack(spacing: 0) {
                // Wall trigger badge
                HStack {
                    Button {
                        showWallPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: selectedWall.icon)
                                .font(.caption.weight(.semibold))
                            Text(selectedWall.displayName)
                                .font(.labelMedium)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .foregroundColor(selectedWall.accentColor)
                        .background(
                            Capsule()
                                .fill(selectedWall.accentColor.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(selectedWall.accentColor.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }
                    .accessibilityLabel("Select wall")
                    .accessibilityValue(selectedWall.displayName)
                    .accessibilityHint("Double tap to change wall")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Sort picker
                HStack {
                    Spacer()
                    Picker("Sort", selection: Binding(
                        get: { activeViewModel.selectedSortOrder },
                        set: { newValue in
                            activeViewModel.selectedSortOrder = newValue
                            activeViewModel.sortOrderChanged(authState: authState)
                        }
                    )) {
                        Text(SortOrder.newest.displayName).tag(SortOrder.newest)
                        Text(SortOrder.oldest.displayName).tag(SortOrder.oldest)
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Sort internships")
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                // Feed
                ScrollView {
                    if activeViewModel.isLoading && activeViewModel.internships.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView("Loading internships...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else if activeViewModel.internships.isEmpty && !activeViewModel.isLoading {
                        VStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "briefcase.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.textSecondary)
                                    .accessibilityHidden(true)
                                Text("No internships yet")
                                    .font(.headline)
                                    .foregroundColor(.textSecondary)
                                Text("Be the first to post an opportunity!")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("No internships yet. Be the first to post an opportunity!")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(activeViewModel.internships) { internship in
                                Button {
                                    coordinator.navigate(to: .internshipDetail(internship))
                                } label: {
                                    InternshipRowView(
                                        internship: internship,
                                        isOwnPosting: internship.author.id == authState.currentUser?.id,
                                        onDelete: { activeViewModel.deleteInternship(internship, authState: authState) },
                                        onTapAuthor: {
                                            coordinator.navigateToChatWithUser(
                                                userId: internship.author.id,
                                                userName: internship.author.profileName
                                            )
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("View internship: \(internship.role) at \(internship.company)")
                                .accessibilityHint("Double tap to view details and comments")
                                .onAppear {
                                    activeViewModel.loadMoreIfNeeded(for: internship, authState: authState)
                                }
                            }

                            if activeViewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView().padding()
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                    }
                }
                .refreshable {
                    await activeViewModel.refreshInternships(authState: authState)
                }

                if let errorMessage = activeViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.accentRed)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Internship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateInternship = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                    }
                    .accessibilityLabel("Post internship")
                    .accessibilityHint("Double tap to post a new internship opportunity")
                }
            }
            .navigationDestination(for: InternshipCoordinator.Destination.self) { destination in
                switch destination {
                case .internshipDetail(let internship):
                    let campusIndex = campusViewModel.internships.firstIndex(where: { $0.id == internship.id })
                    let nationalIndex = nationalViewModel.internships.firstIndex(where: { $0.id == internship.id })

                    if let index = campusIndex {
                        InternshipDetailView(
                            internship: Binding(
                                get: { campusViewModel.internships[index] },
                                set: { campusViewModel.internships[index] = $0 }
                            ),
                            onTapAuthor: { userId, userName in
                                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                            }
                        )
                    } else if let index = nationalIndex {
                        InternshipDetailView(
                            internship: Binding(
                                get: { nationalViewModel.internships[index] },
                                set: { nationalViewModel.internships[index] = $0 }
                            ),
                            onTapAuthor: { userId, userName in
                                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                            }
                        )
                    } else {
                        InternshipDetailView(
                            internship: .constant(internship),
                            onTapAuthor: { userId, userName in
                                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                            }
                        )
                    }
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showCreateInternship) {
            CreateInternshipView {
                activeViewModel.loadInternships(authState: authState)
            }
        }
        .sheet(isPresented: $showWallPicker) {
            WallPickerSheet(selectedWall: $selectedWall)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
        .onChange(of: selectedWall) { _, _ in
            activeViewModel.loadInternships(authState: authState)
        }
        .onAppear {
            campusViewModel.loadInternships(authState: authState)
            nationalViewModel.loadInternships(authState: authState)
        }
        .onDisappear {
            campusViewModel.cleanup()
            nationalViewModel.cleanup()
        }
        .onReceive(blockViewModel.userBlockedPublisher) { blockedUserId in
            campusViewModel.removeInternshipsFromUser(blockedUserId)
            nationalViewModel.removeInternshipsFromUser(blockedUserId)
        }
    }
}

#Preview {
    InternshipView(coordinator: InternshipCoordinator())
        .environmentObject(AuthState())
        .environmentObject(BlockViewModel())
}


