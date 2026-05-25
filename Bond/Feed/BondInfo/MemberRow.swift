// MemberRow.swift
// Bond

import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────────
// MARK: - Member Row
// ─────────────────────────────────────────────────────────────────
struct MemberRow: View {
    let name: String
    let photo: UIImage?
    let postCount: Int
    let maxPosts: Int

    var progress: Double {
        maxPosts > 0 ? Double(postCount) / Double(maxPosts) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(red: 0.88, green: 0.82, blue: 1.0))
                    .frame(width: 48, height: 48)

                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Text(initials(for: name))
                        .font(.app(.balooBold, size: 16))
                        .foregroundColor(Color(red: 0.42, green: 0.35, blue: 0.80))
                }
            }

            // Nome + barra
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name.isEmpty ? "Member" : name)
                        .font(.app(.balooBold, size: 14))
                        .foregroundColor(.black)
                    Spacer()
                    Text("posts")
                        .font(.app(.balooMedium, size: 11))
                        .foregroundColor(.black.opacity(0.4))
                }

                GeometryReader { bar in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.08))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.25, green: 0.60, blue: 0.25))
                            .frame(width: bar.size.width * progress, height: 8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
