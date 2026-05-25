// CreateBondViewModel.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - CreateBond ViewModel
// ─────────────────────────────────────────────────────────────────
@Observable
final class CreateBondViewModel {
    var step: Int = 1
    var bondTitle: String = ""
    var durationIndex: Double = 0
    var showEmojiPicker: Bool = false
    var bondDescription: String = ""
    var reward: String = ""
    var challenges: [String] = []
    var newChallenge: String = ""
    var showAddChallenge: Bool = false
    var generatedCode: String = ""
    var codeCopied: Bool = false
    var isSavingBond: Bool = false
    var saveErrorMessage: String? = nil

    // TODO: Extrair lógica de handleContinue() e generateCode() de CreateABondView
}
