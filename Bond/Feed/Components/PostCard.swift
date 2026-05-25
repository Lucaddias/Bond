// PostCard.swift
// Bond

import SwiftUI
import AVKit
import CloudKit

// ─────────────────────────────────────────────────────────────────
// MARK: - Post Card
// ─────────────────────────────────────────────────────────────────
struct PostCard: View {
    @Binding var post: PostModel
    var player: AVPlayer?
    var currentPlayerID: String = ""
    var currentUserPhoto: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Author ──────────────────────────────────────────
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(authorColor(for: post.authorName))
                        .frame(width: 44, height: 44)

                    let isMe = !currentPlayerID.isEmpty && post.authorPlayerID == currentPlayerID
                    let avatarPhoto = isMe ? (currentUserPhoto ?? post.authorPhoto) : post.authorPhoto

                    if let photo = avatarPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Text(initials(for: post.authorName))
                            .font(.app(.balooBold, size: 16))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName.isEmpty ? "Unknown" : post.authorName)
                        .font(.app(.balooBold, size: 15))
                        .foregroundColor(.black)
                    Text(post.timestamp, style: .relative)
                        .font(.app(.balooMedium, size: 12))
                        .foregroundColor(.black.opacity(0.4))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // ── Media (local ou download lazy do CloudKit) ───────
            ZStack {
                if let img = post.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipped()
                } else if let p = player {
                    VideoPlayer(player: p)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .onAppear { p.play() }
                } else if post.imageAsset != nil || post.videoAsset != nil {
                    ZStack {
                        Rectangle()
                            .fill(Color(red: 0.92, green: 0.92, blue: 0.94))
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                        ProgressView()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            // Download lazy do asset do CloudKit
            .task(id: post.id) {
                if post.image == nil, let asset = post.imageAsset {
                    post.image = try? CloudKitManager.shared.downloadImage(from: asset)
                } else if post.videoURL == nil, let asset = post.videoAsset {
                    post.videoURL = try? CloudKitManager.shared.downloadVideoURL(from: asset)
                }
            }

            // ── Caption + Like ───────────────────────────────────
            HStack(alignment: .top, spacing: 12) {
                Text(post.caption)
                    .font(.app(.balooMedium, size: 14))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                // Coração com sync CloudKit
                Button {
                    // Optimistic update
                    post.isLiked.toggle()
                    post.likes = max(0, post.likes + (post.isLiked ? 1 : -1))
                    // Sync
                    guard let recordID = post.recordID else { return }
                    Task {
                        if let result = try? await CloudKitManager.shared.toggleLike(postRecordID: recordID) {
                            post.isLiked = result.isLiked
                            post.likes   = result.count
                        }
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(post.isLiked ? Color(red: 0.95, green: 0.25, blue: 0.35) : .black.opacity(0.35))
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: post.isLiked)
                        if post.likes > 0 {
                            Text("\(post.likes)")
                                .font(.app(.balooMedium, size: 12))
                                .foregroundColor(.black.opacity(0.4))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func authorColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.42, green: 0.35, blue: 0.80),
            Color(red: 0.20, green: 0.60, blue: 0.86),
            Color(red: 0.90, green: 0.35, blue: 0.35),
            Color(red: 0.25, green: 0.72, blue: 0.58),
            Color(red: 0.95, green: 0.55, blue: 0.15)
        ]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}
