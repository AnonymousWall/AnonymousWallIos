//
//  PollOptionsEditorView.swift
//  AnonymousWallIos
//
//  Inline editor for poll options during post creation.
//  Supports 2–4 option text fields with per-field character counters.
//

import SwiftUI

struct PollOptionsEditorView: View {
    @Binding var pollOptions: [String]
    let maxCharacters: Int
    let canAdd: Bool
    let canRemove: Bool
    let onAdd: () -> Void
    let onRemove: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.callout)
                    .foregroundColor(.primaryPurple)
                    .accessibilityHidden(true)
                Text("Poll Options")
                    .font(.headline)
            }
            .accessibilityAddTraits(.isHeader)

            ForEach(pollOptions.indices, id: \.self) { index in
                PollOptionRow(
                    index: index,
                    text: $pollOptions[index],
                    maxCharacters: maxCharacters,
                    canRemove: canRemove,
                    onRemove: { onRemove(index) }
                )
            }

            if canAdd {
                Button(action: onAdd) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryPurple)
                        Text("Add Option")
                            .foregroundColor(.primaryPurple)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityLabel("Add poll option")
                .accessibilityHint("Double tap to add another poll option")
            }
        }
    }
}

// MARK: - Single Option Row

private struct PollOptionRow: View {
    let index: Int
    @Binding var text: String
    let maxCharacters: Int
    let canRemove: Bool
    let onRemove: () -> Void

    private var isOverLimit: Bool { text.count > maxCharacters }
    private var label: String { "Option \(index + 1)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(text.count)/\(maxCharacters)")
                    .font(.caption2)
                    .foregroundColor(isOverLimit ? .red : .secondary)
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    .accessibilityLabel("Remove \(label)")
                    .accessibilityHint("Double tap to remove this option")
                }
            }
            TextField("Enter option text", text: $text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOverLimit ? Color.red : Color(.separator), lineWidth: 0.5)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}
