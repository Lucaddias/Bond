// ProfileView.swift
// Bond

import SwiftUI
import UIKit
import GameKit
import PhotosUI

enum ProfileFloatField: Equatable {
    case name
    case aboutMe
}

struct ProfileView: View {

    @Environment(\.dismiss) private var dismiss

    // ── Campos editáveis ─────────────────────────────────────────
    @State private var playerPhoto: UIImage? = nil
    @State private var editedName: String   = ""
    @State private var aboutMe: String      = ""
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var customPhoto: UIImage? = nil

    // ── Estado salvo (para detectar mudanças) ────────────────────
    @State private var savedName: String    = ""
    @State private var savedAboutMe: String = ""

    // ── Alerts ───────────────────────────────────────────────────
    @State private var showUnsavedAlert = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var profileFloatField: ProfileFloatField? = nil
    @FocusState private var profileFloatFocused: Bool

    private var displayPhoto: UIImage? { customPhoto ?? playerPhoto }

    private var hasChanges: Bool {
        editedName != savedName || aboutMe != savedAboutMe
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── Background ──────────────────────────────────
                Image("bg_Profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // ── Conteúdo rolável ─────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Botão voltar ─────────────────────────
                        HStack {
                            Button {
                                if hasChanges {
                                    showUnsavedAlert = true
                                } else {
                                    dismiss()
                                }
                            } label: {
                                ZStack {
                                    Image("Botao_voltar")
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 40)
                            }
                            
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.horizontal, 24)

                        // ── Título ───────────────────────────────
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
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 32)

                        // ── Foto + botão troca ───────────────────
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

                        // ── Campo de nome ────────────────────────
                        ZStack {
                            Image("Botao_branco")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)

                            Button { profileFloatField = .name } label: {
                                Text(editedName.isEmpty ? "Name" : editedName)
                                    .font(.app(.balooMedium, size: 28))
                                    .foregroundColor(.black.opacity(0.5))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(width: 260)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(height: 80)
                        .opacity(profileFloatField == .name ? 0 : 1)
                        .animation(.easeInOut(duration: 0.15), value: profileFloatField == .name)

                        // ── About Me ─────────────────────────────
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
                                } else {
                                    Text(aboutMe)
                                        .font(.app(.balooMedium, size: 16))
                                        .foregroundColor(.black.opacity(0.7))
                                        .padding(.horizontal, 24)
                                        .padding(.top, 16)
                                        .lineLimit(8)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { profileFloatField = .aboutMe }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                        .opacity(profileFloatField == .aboutMe ? 0 : 1)
                        .animation(.easeInOut(duration: 0.15), value: profileFloatField == .aboutMe)

                        // ── Botão Save (aparece só quando tem mudanças) ──
                        if hasChanges {
                            Button { saveProfile() } label: {
                                ZStack {
                                    Image("Botao_roxo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                    Text("Save")
                                        .font(.app(.balooBold, size: 24))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 76)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer().frame(height: geo.safeAreaInsets.bottom + 48 + keyboardHeight)
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hasChanges)
                }
                .scrollDismissesKeyboard(.interactively)

                // ── Dark overlay (covers all content, below floating card) ──
                Color.black
                    .opacity(profileFloatField != nil ? 0.75 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(profileFloatField != nil)
                    .onTapGesture { profileFloatField = nil }
                    .animation(.easeInOut(duration: 0.2), value: profileFloatField != nil)

                // ── Floating input overlay ────────────────────────
                if let field = profileFloatField {
                    profileFloatingInputCard(field: field, geo: geo)
                        .offset(y: -keyboardHeight / 2)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: keyboardHeight)
                }
            }
        }
        .ignoresSafeArea()
        .interactiveDismissDisabled(hasChanges)
        .alert("Unsaved Changes", isPresented: $showUnsavedAlert) {
            Button("Leave", role: .destructive) { dismiss() }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("There's unsaved changes. Do you wanna leave?")
        }
        .onAppear { loadProfile() }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { n in
            if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.25)) { keyboardHeight = frame.height }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) { keyboardHeight = 0 }
        }
        .onChange(of: profileFloatField) { _, newVal in
            if newVal != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { profileFloatFocused = true }
            } else {
                profileFloatFocused = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }

    // ── Floating input card ──────────────────────────────────────
    @ViewBuilder
    private func profileFloatingInputCard(field: ProfileFloatField, geo: GeometryProxy) -> some View {
        if field == .aboutMe {
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
                    .focused($profileFloatFocused)
                    .font(.app(.balooMedium, size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .frame(height: 140)
            }
            .padding(.horizontal, 20)
        } else {
            ZStack {
                Image("Botao_branco")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                TextField("Name", text: $editedName)
                    .focused($profileFloatFocused)
                    .font(.app(.balooMedium, size: 28))
                    .foregroundColor(.black.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit { profileFloatField = nil }
                    .frame(width: 260)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(height: 80)
            .padding(.horizontal, 24)
        }
    }

    // ── Save ─────────────────────────────────────────────────────
    private func saveProfile() {
        let nameToSave = editedName.trimmingCharacters(in: .whitespaces)
        if !nameToSave.isEmpty {
            ProfilePhotoStore.saveName(nameToSave)
            savedName = nameToSave
            editedName = nameToSave
        }
        ProfilePhotoStore.saveAboutMe(aboutMe)
        savedAboutMe = aboutMe

        // Haptic de confirmação
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    // ── Load ─────────────────────────────────────────────────────
    private func loadProfile() {
        // Foto
        if let saved = ProfilePhotoStore.load() {
            customPhoto = saved
        }
        // About me
        let storedAbout = ProfilePhotoStore.loadAboutMe()
        aboutMe     = storedAbout
        savedAboutMe = storedAbout

        // Nome: manual > Game Center
        let player = GKLocalPlayer.local
        if let manualName = ProfilePhotoStore.loadName(), !manualName.isEmpty {
            editedName = manualName
        } else if player.isAuthenticated {
            editedName = player.displayName
            ProfilePhotoStore.saveName(player.displayName)
        }
        savedName = editedName

        // Foto do Game Center como fallback
        if player.isAuthenticated, customPhoto == nil {
            player.loadPhoto(for: .normal) { image, _ in
                if let image {
                    DispatchQueue.main.async { playerPhoto = image }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
