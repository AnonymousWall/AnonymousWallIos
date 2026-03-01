//
//  SortPickerSheet.swift
//  AnonymousWallIos
//
//  Bottom sheet for selecting sort order on post walls.
//

import SwiftUI

// MARK: - SortOrder Display Extensions

extension SortOrder {
    var icon: String {
        switch self {
        case .newest:         return "clock"
        case .oldest:         return "calendar"
        case .mostLiked:      return "heart"
        case .leastLiked:     return "heart.slash"
        case .mostCommented:  return "bubble.left.and.bubble.right"
        case .leastCommented: return "bubble.slash"
        }
    }

    var description: String {
        switch self {
        case .newest:         return "Show the latest posts first"
        case .oldest:         return "Show the oldest posts first"
        case .mostLiked:      return "Show the most popular posts first"
        case .leastLiked:     return "Show the least popular posts first"
        case .mostCommented:  return "Show the most discussed posts first"
        case .leastCommented: return "Show the least discussed posts first"
        }
    }

    var accentColor: Color {
        switch self {
        case .newest:         return .accentPurple
        case .oldest:         return .accentOrange
        case .mostLiked:      return .accentPink
        case .leastLiked:     return .accentRed
        case .mostCommented:  return .accentBlue
        case .leastCommented: return .textSecondary
        }
    }
}

// MARK: - SortPickerSheet

struct SortPickerSheet: View {
    @Binding var selectedSort: SortOrder
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Sheet handle
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            SectionLabel(text: "Sort By")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            ForEach(SortOrder.feedOptions, id: \.self) { option in
                SortOptionRow(option: option, isSelected: selectedSort == option) {
                    selectOption(option)
                }
            }

            Spacer()
        }
        .background(Color.surfacePrimary)
    }

    private func selectOption(_ option: SortOrder) {
        selectedSort = option
        HapticFeedback.selection()
        Task {
            try? await Task.sleep(for: .seconds(0.15))
            dismiss()
        }
    }
}

// MARK: - SortOptionRow

struct SortOptionRow: View {
    let option: SortOrder
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconBadge(systemName: option.icon, color: option.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [option.accentColor, option.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Circle()
                        .stroke(Color.borderMedium, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.displayName). \(option.description)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    SortPickerSheet(selectedSort: .constant(.newest))
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
}
