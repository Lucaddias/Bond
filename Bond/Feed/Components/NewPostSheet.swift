// NewPostSheet.swift
// Bond

import SwiftUI
import AVKit

// ─────────────────────────────────────────────────────────────────
// MARK: - New Post Sheet (caption)
// ─────────────────────────────────────────────────────────────────
struct NewPostSheet: View {
    let image: UIImage?
    let videoURL: URL?
    var onPost: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var caption: String = ""
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Image("bg_Post")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────
            ZStack {
                Text("New Post")
                    .font(.app(.balooBold, size: 22))
                    .foregroundColor(.black)

                HStack {
                    Button { dismiss() } label: {
                        ZStack {
                            Image("Botao_voltar")
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 16)

            // Thumbnail
            ZStack {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                } else if let p = player {
                    VideoPlayer(player: p)
                        .frame(height: 220)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            // Caption field
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                    .frame(height: 100)

                if caption.isEmpty {
                    Text("Write a caption…")
                        .font(.app(.balooMedium, size: 15))
                        .foregroundColor(.black.opacity(0.3))
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $caption)
                    .font(.app(.balooMedium, size: 15))
                    .foregroundColor(.black.opacity(0.7))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(height: 100)
                    .padding(.horizontal, 10)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Post button
            Button {
                onPost(caption)
                dismiss()
            } label: {
                ZStack {
                    Image("Botao_continuar")
                        .frame(maxWidth: .infinity)
                    Text("Post")
                        .font(.app(.balooBold, size: 20))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }

            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            Spacer()
        }
        .onAppear {
            if let url = videoURL {
                player = AVPlayer(url: url)
                player?.play()
            }
        }
        } // ZStack
    }
}
