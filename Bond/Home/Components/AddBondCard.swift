// AddBondCard.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Add Bond Card
// ─────────────────────────────────────────────────────────────────
struct AddBondCard: View {
    var isLocked: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: isLocked ? {} : action) {
            ZStack {
                RoundedRectangle(cornerRadius: 60)
                    .fill(isLocked ? Color(red: 0.93, green: 0.93, blue: 0.95) : Color.white)
                    .shadow(color: .black.opacity(isLocked ? 0.06 : 0.3), radius: 12, x: 5, y: 4)

                if isLocked {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.black.opacity(0.25))
                        Text("Bond limit reached")
                            .font(.app(.balooBold, size: 15))
                            .foregroundColor(.black.opacity(0.30))
                        Text("Upgrade to Premium for more")
                            .font(.app(.balooMedium, size: 12))
                            .foregroundColor(.black.opacity(0.20))
                    }
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}
