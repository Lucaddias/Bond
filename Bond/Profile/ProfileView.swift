// ProfileView.swift
// Bond

import SwiftUI
import UIKit
import GameKit
import AuthenticationServices
import PhotosUI

struct ProfileView: View {

    // ── Estado ───────────────────────────────────────────────────
    @State private var playerName: String = ""
    @State private var playerPhoto: UIImage? = nil
    @State private var editedName: String = ""
    @State private var aboutMe: String = ""

    // Troca de foto
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var customPhoto: UIImage? = nil

    // Foto exibida: custom → gamecenter → nil
    private var displayPhoto: UIImage? { customPhoto ?? playerPhoto }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── Background ──
                Image("bg_Profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // ── Conteúdo rolável ──
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Título ──
                        VStack(spacing: -20) {
                            Text("Organize")
                                .font(.app(.porkysRegular, size: 60))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .kerning(2)

                            Text("your profile")
                                .font(.app(.porkysHeavy, size: 60))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .kerning(2)
                        }
                        .padding(.top, geo.safeAreaInsets.top + 32)
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 40)

                        // ── Foto + botão troca ──
                        ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let img = displayPhoto {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .padding(28)
                                            .foregroundColor(.black.opacity(0.5))
                                    }
                                }
                                .frame(width: 200, height: 200)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                        
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                Image("Botao_Adicionar_Foto")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 54, height: 54)
                                    .offset(x: 4, y: 4)
                                    .allowsHitTesting(false)
                            }
                        }
                        .onChange(of: photoPickerItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run { customPhoto = image }
                                }
                            }
                        }

                        Spacer().frame(height: 32)

                        // ── Campo de nome ──
                        ZStack {
                            Image("Botao_branco")
                                

                            TextField("Name", text: $editedName)
                                .font(.app(.balooMedium, size: 28))
                                .foregroundColor(.black.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .autocorrectionDisabled()
                                .frame(width: 260)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(height: 80)

                        

                        // ── About Me ──
                        VStack(alignment: .leading, spacing: -4) {
                            Text("About me")
                                .font(.app(.porkysRegular, size: 24))
                                .foregroundColor(.black)
                                .padding(.leading, 45)
                                
                                .padding(.bottom, 5)
                                .kerning(1)
                                

                            Image("AboutSection")
                                .frame(maxWidth: .infinity)

                                    if aboutMe.isEmpty {
                                        Text("Tell ur friends a bit about you")
                                            .font(.app(.balooMedium, size: 16))
                                            .foregroundColor(.black.opacity(0.3))
                                            .padding(.horizontal, 40)
                                            .padding(.top, 20)
                                            .allowsHitTesting(false)
                                    }
                                    TextEditor(text: $aboutMe)
                                        .font(.app(.balooMedium, size: 16))
                                        .foregroundColor(.black.opacity(0.6))
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .padding(.horizontal, 12)
                                        .padding(.top, 8)
                                
                                .clipped()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)

                        Spacer().frame(height: geo.safeAreaInsets.bottom + 48)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 50)
            }
        }
        .ignoresSafeArea()
        .onAppear { loadGameCenterPlayer() }
    }

    // ── Game Center ──────────────────────────────────────────────
    private func loadGameCenterPlayer() {
        let player = GKLocalPlayer.local
        if player.isAuthenticated {
            playerName = player.displayName
            editedName = player.displayName
            player.loadPhoto(for: .normal) { image, _ in
                if let image {
                    DispatchQueue.main.async { playerPhoto = image }
                }
            }
        } else {
            editedName = ""
        }
    }
}

#Preview {
    ProfileView()
}
