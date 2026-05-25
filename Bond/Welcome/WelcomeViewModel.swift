// WelcomeViewModel.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Welcome ViewModel
// ─────────────────────────────────────────────────────────────────
@Observable
final class WelcomeViewModel {
    var code: String = ""
    var joinError: String? = nil
    var isJoining: Bool = false

    // TODO: Extrair lógica de attemptJoin() de WelcomeView
}
