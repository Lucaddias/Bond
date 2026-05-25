// HeaderCard.swift
// Bond

import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────────
// MARK: - Header Card
// ─────────────────────────────────────────────────────────────────
struct HeaderCard: View {
    let name: String
    let photo: UIImage?
    var onPhotoTap: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color.white

                HStack(alignment: .center) {
                    Text("HI, \(name)!")
                        .font(.app(.balooBold, size: 36))
                        .foregroundColor(.black.opacity(0.5))
                        .padding(.top, 60)
                        .padding(.leading, 20)
                        .padding(35)

                    // Foto do Game Center — clicável para ir ao Perfil
                    Button(action: onPhotoTap) {
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
                        .frame(width: 85, height: 85)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(red: 0.90, green: 0.90, blue: 0.92), lineWidth: 2))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 42)
                }
                .padding(.leading, 12)
                .padding(.bottom, 24)
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
}
