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
            
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.80, green: 0.80, blue: 0.82))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text("New Post")
                .font(.app(.balooBold, size: 22))
                .foregroundColor(.black)
                .padding(.bottom, 0)
                .padding(.top, 60)
                .padding(.trailing, 210)

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

// ─────────────────────────────────────────────────────────────────
// MARK: - Camera Picker
// ─────────────────────────────────────────────────────────────────
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var videoURL: URL?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ p: CameraPickerView) { parent = p }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            if let url = info[.mediaURL] as? URL {
                parent.videoURL = url
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Gallery Picker (PHPicker — fotos + vídeos)
// ─────────────────────────────────────────────────────────────────
struct GalleryPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var videoURL: URL?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .any(of: [.images, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: GalleryPickerView
        init(_ p: GalleryPickerView) { parent = p }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    DispatchQueue.main.async {
                        self.parent.image = obj as? UIImage
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier("public.movie") {
                provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, _ in
                    guard let url else { return }
                    // Copia para temp dir para manter acesso após o picker fechar
                    let tmpURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(url.pathExtension)
                    try? FileManager.default.copyItem(at: url, to: tmpURL)
                    DispatchQueue.main.async {
                        self.parent.videoURL = tmpURL
                    }
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────
#Preview {
    FeedView(bond: .constant(BondModel(name: "Summer Squad")))
}
#Preview("New Post Sheet") {
    let sampleImage = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300)).image { ctx in
        UIColor.systemIndigo.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        UIColor.white.setFill()
        ctx.fill(CGRect(x: 150, y: 100, width: 100, height: 100))
    }
    return NewPostSheet(image: sampleImage, videoURL: nil) { _ in }
}
