// FeedView.swift
// Bond

import SwiftUI
import AVKit
import PhotosUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Feed View
// ─────────────────────────────────────────────────────────────────
struct FeedView: View {

    @Binding var bond: BondModel
    @Environment(\.dismiss) private var dismiss

    // ── Media picker state ──────────────────────────────────────
    @State private var showCamera         = false
    @State private var pickedImage: UIImage?  = nil
    @State private var pickedVideoURL: URL?   = nil
    @State private var showNewPost        = false

    // ── Player cache ────────────────────────────────────────────
    // Evita recriar AVPlayer a cada rebuild
    @State private var playerCache: [UUID: AVPlayer] = [:]

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── Background ──────────────────────────────────
                Image("bg_Feed")
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
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geo.safeAreaInsets.top + 60)
                    .padding(.bottom, 16)

                    // ── Posts ────────────────────────────────────
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            if bond.posts.isEmpty {
                                emptyState
                                    .padding(.top, 60)
                            } else {
                                ForEach(bond.posts.indices, id: \.self) { index in
                                    PostCard(
                                        post: $bond.posts[index],
                                        player: playerFor(post: bond.posts[index])
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 100)
                    }
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
        // ── Novo post (caption) ──────────────────────────────────
        .sheet(isPresented: $showNewPost, onDismiss: clearPicked) {
            NewPostSheet(
                image: pickedImage,
                videoURL: pickedVideoURL
            ) { caption in
                let post = PostModel(
                    authorName: "Me",          // substituir pelo nome do player GK
                    authorPhoto: nil,
                    image: pickedImage,
                    videoURL: pickedVideoURL,
                    caption: caption
                )
                bond.posts.insert(post, at: 0)
                clearPicked()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Author ──────────────────────────────────────────
            HStack(spacing: 10) {
                Group {
                    if let photo = post.authorPhoto {
                        Image(uiImage: photo)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(red: 0.88, green: 0.88, blue: 0.90))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.black.opacity(0.35))
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.app(.balooBold, size: 15))
                        .foregroundColor(.black)
                    Text(post.timestamp, style: .time)
                        .font(.app(.balooMedium, size: 12))
                        .foregroundColor(.black.opacity(0.4))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // ── Media ────────────────────────────────────────────
            ZStack {
                if let img = post.image {
                    Image(uiImage: img)
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                } else if let p = player {
                    VideoPlayer(player: p)
                        .frame(height: 260)
                        .onAppear { p.play() }
                } else {
                    Rectangle()
                        .fill(Color(red: 0.92, green: 0.92, blue: 0.94))
                        .frame(height: 260)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)

            // ── Caption + Like ───────────────────────────────────
            HStack(alignment: .top, spacing: 12) {
                Text(post.caption)
                    .font(.app(.balooMedium, size: 14))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                // Coração
                Button {
                    post.isLiked.toggle()
                    post.likes = max(0, post.likes + (post.isLiked ? 1 : -1))
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
                .padding(.bottom, 20)

            // Thumbnail
            ZStack {
                if let img = image {
                    Image(uiImage: img)
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
            .padding(.bottom, 32)
        }
        .onAppear {
            if let url = videoURL {
                player = AVPlayer(url: url)
                player?.play()
            }
        }
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
