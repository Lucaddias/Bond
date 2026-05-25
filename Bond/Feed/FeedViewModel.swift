// FeedViewModel.swift
// Bond

import SwiftUI
import AVFoundation

// ─────────────────────────────────────────────────────────────────
// MARK: - Feed ViewModel
// ─────────────────────────────────────────────────────────────────
@Observable
final class FeedViewModel {
    var isLoading: Bool = false
    var playerCache: [UUID: AVPlayer] = [:]

    // TODO: Extrair lógica de loadPosts(), submitPost() e playerFor() de FeedView
}
