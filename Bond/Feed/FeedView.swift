// FeedView.swift
// Bond

import SwiftUI
import AVKit
import PhotosUI
import CloudKit

// ─────────────────────────────────────────────────────────────────
// MARK: - Feed View
// ─────────────────────────────────────────────────────────────────
struct FeedView: View {

    @Binding var bond: BondModel
    var onLeaveBond: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    // ── Media picker state ──────────────────────────────────────
    @State private var showCamera         = false
    @State private var pickedImage: UIImage?  = nil
    @State private var pickedVideoURL: URL?   = nil
    @State private var showNewPost        = false
    @State private var showBondInfo       = false

    // ── Perfil do usuário atual ──────────────────────────────────
    private var currentPlayerID: String { CloudKitManager.shared.currentPlayerID }
    @State private var currentUserPhoto: UIImage? = ProfilePhotoStore.load()

    // ── Player cache ────────────────────────────────────────────
    // Evita recriar AVPlayer a cada rebuild
    @State private var playerCache: [UUID: AVPlayer] = [:]

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── Background ──────────────────────────────────
                Image("bg_Feed")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()

                // ── Conteúdo ────────────────────────────────────
                VStack(spacing: 0) {

                    // ── Header ──────────────────────────────────
                    ZStack {
                        Text(bond.name)
                            .font(.app(.balooBold, size: 28))
                            .foregroundColor(.black)

                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button { showBondInfo = true } label: {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geo.safeAreaInsets.top + 60)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        // Recorta o bg_Feed alinhado ao topo para cobrir posts que sobem
                        GeometryReader { _ in
                            Image("bg_Feed")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        }
                        .ignoresSafeArea()
                    )

                    // ── Posts ────────────────────────────────────
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            if bond.posts.isEmpty {
                                emptyState.padding(.top, 60)
                            } else {
                                ForEach(bond.posts.indices, id: \.self) { index in
                                    PostCard(
                                        post: $bond.posts[index],
                                        player: playerFor(post: bond.posts[index]),
                                        currentPlayerID: currentPlayerID,
                                        currentUserPhoto: currentUserPhoto
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 100)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable { await loadPosts() }
                }

                // ── Botão câmera — canto inferior direito ────────
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { showCamera = true } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.42, green: 0.35, blue: 0.80))
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 24)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                    }
                }
            }
        }
        .ignoresSafeArea()
        // Fetch inicial dos posts
        .task { await loadPosts() }
        // ── Câmera (com acesso à galeria embutido) ───────────────
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(image: $pickedImage, videoURL: $pickedVideoURL)
                .ignoresSafeArea()
                .onDisappear {
                    if pickedImage != nil || pickedVideoURL != nil {
                        showNewPost = true
                    }
                }
        }
        // ── Bond Info ────────────────────────────────────────────
        .fullScreenCover(isPresented: $showBondInfo) {
            BondInfoView(bond: $bond, onLeaveBond: {
                // Fecha BondInfoView e propaga o leave para o HomeView
                showBondInfo = false
                onLeaveBond()
            })
        }
        // ── Novo post (caption) ──────────────────────────────────
        .sheet(isPresented: $showNewPost, onDismiss: clearPicked) {
            NewPostSheet(
                image: pickedImage,
                videoURL: pickedVideoURL
            ) { caption in
                submitPost(caption: caption)
            }
        }
    }

    // ── CloudKit: fetch ──────────────────────────────────────────
    private func loadPosts() async {
        guard let recordID = bond.recordID else {
            // Bond ainda não sincronizado — mantém posts locais
            return
        }
        do {
            let posts = try await CloudKitManager.shared.fetchPosts(for: recordID)
            // Marca quais posts o usuário curtiu
            let likedIDs = try await CloudKitManager.shared.fetchLikedPostIDs()
            bond.posts = posts.map { post in
                var p = post
                if let rid = p.recordID {
                    p.isLiked = likedIDs.contains(rid.recordName)
                }
                return p
            }
        } catch {
            // Falha silenciosa — mantém posts locais/cache
        }
    }

    // ── CloudKit: create post ─────────────────────────────────────
    private func submitPost(caption: String) {
        let authorName = CloudKitManager.shared.currentPlayerName
        var localPost  = PostModel(
            authorName: authorName,
            image: pickedImage,
            videoURL: pickedVideoURL,
            caption: caption
        )
        localPost.authorPlayerID = CloudKitManager.shared.currentPlayerID

        // Optimistic insert
        bond.posts.insert(localPost, at: 0)
        clearPicked()

        // Persiste no CloudKit se bond já está salvo
        guard let bondRecordID = bond.recordID else { return }
        Task {
            do {
                let saved = try await CloudKitManager.shared.createPost(localPost, bondRecordID: bondRecordID)
                if let idx = bond.posts.firstIndex(where: { $0.id == localPost.id }) {
                    bond.posts[idx] = saved
                }
            } catch {
                // Mantém post local mesmo sem sync
            }
        }
    }

    // ── Helpers ──────────────────────────────────────────────────
    private var emptyState: some View {
        VStack(spacing: 0) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundColor(.black.opacity(0.18))
            Text("No posts yet")
                .font(.app(.balooBold, size: 20))
                .foregroundColor(.black.opacity(0.35))
            Text("Be the first to share a moment!")
                .font(.app(.balooMedium, size: 15))
                .foregroundColor(.black.opacity(0.25))
        }
    }

    private func playerFor(post: PostModel) -> AVPlayer? {
        guard let url = post.videoURL else { return nil }
        if let cached = playerCache[post.id] { return cached }
        let p = AVPlayer(url: url)
        playerCache[post.id] = p
        return p
    }

    private func clearPicked() {
        pickedImage = nil
        pickedVideoURL = nil
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────
#Preview {
    FeedView(bond: .constant(BondModel(name: "Summer Squad")))
}
