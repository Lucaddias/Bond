// LoadingView.swift
// Bond

import SwiftUI
import AVFoundation

// ─────────────────────────────────────────────────────────────────
// MARK: - Loading View
// ─────────────────────────────────────────────────────────────────
struct LoadingView: View {
    var onFinished: () -> Void = {}

    @State private var player: AVPlayer? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background full-screen
                Image("bg_PreLoading")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // Vídeo full-screen sem controles
                if let player {
                    AVPlayerLayerView(player: player)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { setupPlayer() }
        .onDisappear { player?.pause() }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "preLoading", withExtension: "mov") else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onFinished() }
            return
        }

        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer

        // Vídeo terminou normalmente
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in onFinished() }

        // Vídeo falhou (codec não suportado no Simulator — no device funciona)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { onFinished() }
        }

        avPlayer.play()
        avPlayer.rate = 2.0

        // Fallback: se em 8s o vídeo não terminou (travou/falhou silenciosamente)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak avPlayer] in
            guard let p = avPlayer else { return }
            if p.timeControlStatus != .playing {
                onFinished()
            }
        }
    }
}
