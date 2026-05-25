// ChallengeChip.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Challenge Chip
// ─────────────────────────────────────────────────────────────────
struct ChallengeChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.app(.balooMedium, size: 13))
                .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.75))
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.75))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 0.35, green: 0.25, blue: 0.75), lineWidth: 1.5)
        )
    }
}
