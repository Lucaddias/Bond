// BondInfoViewModel.swift
// Bond

import SwiftUI
import CloudKit

// ─────────────────────────────────────────────────────────────────
// MARK: - BondInfo ViewModel
// ─────────────────────────────────────────────────────────────────
@Observable
final class BondInfoViewModel {
    var showLeaveAlert: Bool = false
    var leaveErrorMessage: String? = nil
    var coverErrorMessage: String? = nil
    var showCameraForCover: Bool = false

    // TODO: Extrair lógica de saveCover() e leave bond de BondInfoView
}
