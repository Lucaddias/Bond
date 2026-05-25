// ProfileView.swift
// Bond

import SwiftUI
import UIKit
import GameKit
import PhotosUI

struct ProfileView: View {

    @State private var playerName: String = ""
    @State private var playerPhoto: UIImage? = nil
    @State private var editedName: String = ""
    @State private var aboutMe: String = ""
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var customPhoto: UIImage? = nil

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
                            }
                        }
                        .onChange(of: photoPickerItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        customPhoto = image
                                        ProfilePhotoStore.save(image)
                                    }
                                }
                            }
                        }

                        Spacer().frame(height: 32)

                        // ── Campo de nome ──
                        ZStack {
                            Image("Botao_branco")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)

                            TextField("Name", text: $editedName)
                                .font(.app(.balooMedium, size: 28))
                                .foregroundColor(.black.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .autocorrectionDisabled()
                                .textFieldStyle(.plain)
                                .frame(width: 260)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(height: 80)

                        // ── About Me ──
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About me")
                                .font(.app(.porkysRegular, size: 24))
                                .foregroundColor(.black)
                                .padding(.leading, 20)
                                .kerning(1)

                            ZStack(alignment: .topLeading) {
                                Image("AboutSection")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)

                                if aboutMe.isEmpty {
                                    Text("Tell ur friends a bit about you")
                                        .font(.app(.balooMedium, size: 16))
                                        .foregroundColor(.black.opacity(0.3))
                                        .padding(.horizontal, 24)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }

                                TextEditor(text: $aboutMe)
                                    .font(.app(.balooMedium, size: 16))
                                    .foregroundColor(.black.opacity(0.7))
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .padding(.horizontal, 12)
                                    .padding(.top, 8)
                                    .frame(height: 140)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)

                        Spacer().frame(height: geo.safeAreaInsets.bottom + 48)
                    }
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .ignoresSafeArea()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
        }
        .onAppear { loadGameCenterPlayer() }
        .onDisappear {
            if !editedName.isEmpty {
                ProfilePhotoStore.saveName(editedName)
            }
        }
    }

    private func loadGameCenterPlayer() {
        if let saved = ProfilePhotoStore.load() {
            customPhoto = saved
        }
        let player = GKLocalPlayer.local
        if player.isAuthenticated {
            let name = player.displayName
            playerName = name
            editedName = name
            ProfilePhotoStore.saveName(name)
            if customPhoto == nil {
                player.loadPhoto(for: .normal) { image, _ in
                    if let image {
                        DispatchQueue.main.async { playerPhoto = image }
                    }
                }
            }
        } else if let saved = ProfilePhotoStore.loadName(), !saved.isEmpty {
            editedName = saved
        }
    }
}

#Preview {
    ProfileView()
}
