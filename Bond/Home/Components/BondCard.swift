// BondCard.swift
// Bond

import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────────
// MARK: - Bond Card
// ─────────────────────────────────────────────────────────────────
struct BondCard: View {
    let bond: BondModel
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let img = bond.coverImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image("bg_BondFoto")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(bond.name)
                    .font(.app(.balooBold, size: 22))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
