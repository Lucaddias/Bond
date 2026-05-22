// LoadingView.swift
// Bond

import SwiftUI
import AVFoundation
import UIKit

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
            onFinished()
            return
        }

        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        self.player = avPlayer

        // Registra o observer antes de chamar play()
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            onFinished()
        }

        // play() primeiro, depois rate para garantir 4× em todos os casos
        avPlayer.play()
        avPlayer.rate = 2.0
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - AVPlayerLayer wrapper (sem controles nativos)
// ─────────────────────────────────────────────────────────────────
struct AVPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.setPlayer(player)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.setPlayer(player)
    }
}

final class PlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setPlayer(_ player: AVPlayer) {
        playerLayer.player = player
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
