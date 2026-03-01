//
//  WallPickerSheet.swift
//  AnonymousWallIos
//
//  Bottom sheet for selecting Campus or National wall on Internship and Marketplace screens.
//

import SwiftUI

// MARK: - WallType Display Extensions

extension WallType {
    var description: String {
        switch self {
        case .campus:   return "Posts from your school only"
        case .national: return "Posts from all schools"
        }
    }

    var icon: String {
        switch self {
        case .campus:   return "building.columns"
        case .national: return "globe"
        }
    }

    var accentColor: Color {
        switch self {
        case .campus:   return .accentPurple
        case .national: return .accentBlue
        }
    }
}

// MARK: - WallPickerSheet

struct WallPickerSheet: View {
    @Binding var selectedWall: WallType
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Sheet handle
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            SectionLabel(text: "Community")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            ForEach(WallType.allCases, id: \.self) { wall in
                WallOptionRow(wall: wall, isSelected: selectedWall == wall) {
                    selectWall(wall)
                }
            }

            Spacer()
        }
        .background(Color.surfacePrimary)
    }

    private func selectWall(_ wall: WallType) {
        selectedWall = wall
        HapticFeedback.selection()
        Task {
            try? await Task.sleep(for: .seconds(0.15))
            dismiss()
        }
    }
}

// MARK: - WallOptionRow

struct WallOptionRow: View {
    let wall: WallType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconBadge(systemName: wall.icon, color: wall.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(wall.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    Text(wall.description)
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
                                    colors: [wall.accentColor, wall.accentColor.opacity(0.7)],
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
        .accessibilityLabel("\(wall.displayName). \(wall.description)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    WallPickerSheet(selectedWall: .constant(.campus))
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
}
