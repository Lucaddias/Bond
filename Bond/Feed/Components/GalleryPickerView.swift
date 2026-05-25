// GalleryPickerView.swift
// Bond

import SwiftUI
import PhotosUI

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
