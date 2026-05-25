// HomeViewModel.swift
// Bond

import SwiftUI
import UIKit
import GameKit

// ─────────────────────────────────────────────────────────────────
// MARK: - Home ViewModel
// ─────────────────────────────────────────────────────────────────
@Observable
final class HomeViewModel {
    var playerName: String = ProfilePhotoStore.loadName() ?? "Player"
    var playerPhoto: UIImage? = nil

    // TODO: Extrair lógica de loadPlayerInfo() e setupAndLoadGameCenter() de HomeView
}
