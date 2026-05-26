// HeaderCard.swift
// Bond

import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────────
// MARK: - Header Card
// ─────────────────────────────────────────────────────────────────
@MainActor
struct HeaderCard: View {
    let name: String
    let photo: UIImage?
    var onPhotoTap: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color.white

                Text("HI, \(name)!")
                    .font(.app(.balooBold, size: 32))
                    .foregroundColor(.black.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: geo.size.width - 165, alignment: .leading)
                    .padding(.leading, 32)
                    .padding(.bottom, 20)

                HStack {
                    Spacer()

                    // Foto do Game Center — clicável para ir ao Perfil
                    Button(action: onPhotoTap) {
                        profileImage
                            .frame(width: 85, height: 85)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 2))
                            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 32)
                }
                .padding(.bottom, 26)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 60,
                    bottomTrailingRadius: 60,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 6)
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundColor(.black.opacity(0.50))
            }
        }
    }
}

#Preview("HeaderCard") {
    HeaderCard(
        name: "Arthur manflansf anlsfna",
        photo: UIImage(named: "HandView"),
        onPhotoTap: {}
    )
}
