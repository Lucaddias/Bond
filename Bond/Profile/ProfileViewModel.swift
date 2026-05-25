// ProfileViewModel.swift
// Bond

import SwiftUI
import UIKit
import GameKit
import PhotosUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Profile ViewModel
// ─────────────────────────────────────────────────────────────────
@Observable
final class ProfileViewModel {
    var playerName: String = ""
    var playerPhoto: UIImage? = nil
    var editedName: String = ""
    var aboutMe: String = ""
    var customPhoto: UIImage? = nil

    // TODO: Extrair lógica de loadGameCenterPlayer() de ProfileView
}
