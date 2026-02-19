//
//  InternshipView.swift
//  AnonymousWallIos
//
//  Internship feed view - campus and national walls
//

import SwiftUI

struct InternshipView: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var campusViewModel = InternshipFeedViewModel(wallType: .campus)
    @StateObject private var nationalViewModel = InternshipFeedViewModel(wallType: .national)
    @State private var selectedWall: WallType = .campus
    @State private var showCreateInternship = false

    private var activeViewModel: InternshipFeedViewModel {
        selectedWall == .campus ? campusViewModel : nationalViewModel
    }

    private let minimumScrollableHeight: CGFloat = 300

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Wall picker
                Picker("Wall", selection: $selectedWall) {
                    ForEach(WallType.allCases, id: \.self) { wall in
                        Text(wall.displayName).tag(wall)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
                .accessibilityLabel("Select wall")
                .accessibilityValue(selectedWall.displayName)
                .onChange(of: selectedWall) { _, _ in
                    HapticFeedback.selection()
                    activeViewModel.loadInternships(authState: authState)
                }

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
                        ForEach(FeedSortOrder.allCases, id: \.self) { order in
                            Text(order.displayName).tag(order)
                        }
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
                                    .foregroundColor(.gray)
                                    .accessibilityHidden(true)
                                Text("No internships yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Be the first to post an opportunity!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("No internships yet. Be the first to post an opportunity!")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(activeViewModel.internships) { internship in
                                if let index = activeViewModel.internships.firstIndex(where: { $0.id == internship.id }) {
                                    NavigationLink(destination: InternshipDetailView(
                                        internship: Binding(
                                            get: { activeViewModel.internships[index] },
                                            set: { activeViewModel.internships[index] = $0 }
                                        )
                                    )) {
                                        InternshipRowView(
                                            internship: internship,
                                            isOwnPosting: internship.author.id == authState.currentUser?.id,
                                            onDelete: { activeViewModel.deleteInternship(internship, authState: authState) }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel("View internship: \(internship.role) at \(internship.company)")
                                    .accessibilityHint("Double tap to view details and comments")
                                    .onAppear {
                                        activeViewModel.loadMoreIfNeeded(for: internship, authState: authState)
                                    }
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
                        .foregroundColor(.red)
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
        }
        .sheet(isPresented: $showCreateInternship) {
            CreateInternshipView {
                activeViewModel.loadInternships(authState: authState)
            }
        }
        .onAppear {
            campusViewModel.loadInternships(authState: authState)
            nationalViewModel.loadInternships(authState: authState)
        }
        .onDisappear {
            campusViewModel.cleanup()
            nationalViewModel.cleanup()
        }
    }
}

#Preview {
    InternshipView()
        .environmentObject(AuthState())
}

