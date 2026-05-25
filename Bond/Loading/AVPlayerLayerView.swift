// AVPlayerLayerView.swift
// Bond

import SwiftUI
import AVFoundation
import UIKit

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
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setPlayer(_ player: AVPlayer) {
        playerLayer.player = player
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        playerLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }
}
