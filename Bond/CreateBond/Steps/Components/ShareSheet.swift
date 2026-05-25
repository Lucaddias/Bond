// ShareSheet.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Share Sheet (UIActivityViewController)
// ─────────────────────────────────────────────────────────────────
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
