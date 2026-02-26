//
//  MarketView.swift
//  AnonymousWallIos
//
//  Marketplace feed view - campus and national walls
//

import SwiftUI

struct MarketView: View {
    @EnvironmentObject var authState: AuthState
    @ObservedObject var coordinator: MarketplaceCoordinator
    @StateObject private var campusViewModel = MarketplaceFeedViewModel(wallType: .campus)
    @StateObject private var nationalViewModel = MarketplaceFeedViewModel(wallType: .national)
    @State private var selectedWall: WallType = .campus
    @State private var showCreateItem = false

    private var activeViewModel: MarketplaceFeedViewModel {
        selectedWall == .campus ? campusViewModel : nationalViewModel
    }

    private let minimumScrollableHeight: CGFloat = 300

    var body: some View {
        NavigationStack(path: $coordinator.path) {
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
                    activeViewModel.loadItems(authState: authState)
                }

                // Sort and category controls
                HStack {
                    Picker("Sort", selection: Binding(
                        get: { activeViewModel.selectedSortOrder },
                        set: { newValue in
                            activeViewModel.selectedSortOrder = newValue
                            activeViewModel.sortOrderChanged(authState: authState)
                        }
                    )) {
                        ForEach(MarketplaceSortOrder.allCases, id: \.self) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Sort items")

                    Spacer()

                    Picker("Category", selection: Binding(
                        get: { activeViewModel.selectedCategory },
                        set: { newValue in
                            activeViewModel.selectedCategory = newValue
                            activeViewModel.categoryChanged(authState: authState)
                        }
                    )) {
                        Text("All Categories").tag(MarketplaceCategory?.none)
                        ForEach(MarketplaceCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(Optional(cat))
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Filter by category")
                    .accessibilityValue(activeViewModel.selectedCategory?.displayName ?? "All Categories")
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                // Feed
                ScrollView {
                    if activeViewModel.isLoading && activeViewModel.items.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView("Loading items...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else if activeViewModel.items.isEmpty && !activeViewModel.isLoading {
                        VStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                    .accessibilityHidden(true)
                                Text("No items yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Be the first to list something!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("No items yet. Be the first to list something!")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: minimumScrollableHeight)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(activeViewModel.items) { item in
                                Button {
                                    coordinator.navigate(to: .marketplaceDetail(item))
                                } label: {
                                    MarketplaceRowView(
                                        item: item,
                                        isOwnItem: item.author.id == authState.currentUser?.id,
                                        onDelete: { activeViewModel.deleteItem(item, authState: authState) },
                                        onTapAuthor: {
                                            coordinator.navigateToChatWithUser(
                                                userId: item.author.id,
                                                userName: item.author.profileName
                                            )
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("View listing: \(item.title)")
                                .accessibilityHint("Double tap to view details and comments")
                                .onAppear {
                                    activeViewModel.loadMoreIfNeeded(for: item, authState: authState)
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
                    await activeViewModel.refreshItems(authState: authState)
                }

                if let errorMessage = activeViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateItem = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                    }
                    .accessibilityLabel("List item")
                    .accessibilityHint("Double tap to create a new marketplace listing")
                }
            }
            .navigationDestination(for: MarketplaceCoordinator.Destination.self) { destination in
                switch destination {
                case .marketplaceDetail(let item):
                    let campusIndex = campusViewModel.items.firstIndex(where: { $0.id == item.id })
                    let nationalIndex = nationalViewModel.items.firstIndex(where: { $0.id == item.id })

                    if let index = campusIndex {
                        MarketplaceDetailView(
                            item: Binding(
                                get: { campusViewModel.items[index] },
                                set: { campusViewModel.items[index] = $0 }
                            ),
                            onTapAuthor: { userId, userName in
                                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                            }
                        )
                    } else if let index = nationalIndex {
                        MarketplaceDetailView(
                            item: Binding(
                                get: { nationalViewModel.items[index] },
                                set: { nationalViewModel.items[index] = $0 }
                            ),
                            onTapAuthor: { userId, userName in
                                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                            }
                        )
                    } else {
                        MarketplaceDetailView(
                            item: .constant(item),
                            onTapAuthor: { userId, userName in
                                coordinator.navigateToChatWithUser(userId: userId, userName: userName)
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateItem) {
            CreateMarketplaceView {
                activeViewModel.loadItems(authState: authState)
            }
        }
        .onAppear {
            campusViewModel.loadItems(authState: authState)
            nationalViewModel.loadItems(authState: authState)
        }
        .onDisappear {
            campusViewModel.cleanup()
            nationalViewModel.cleanup()
        }
    }

}

#Preview {
    MarketView(coordinator: MarketplaceCoordinator())
        .environmentObject(AuthState())
}


