// ShareCodeSheet.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Share Code Sheet (reutiliza StepShareView)
// ─────────────────────────────────────────────────────────────────
struct ShareCodeSheet: View {
    let bondName: String
    let inviteCode: String
    let maxParticipants: Int
    @Binding var copied: Bool

    var body: some View {
        StepShareView(
            bondName: bondName,
            inviteCode: inviteCode,
            maxParticipants: maxParticipants,
            copied: $copied
        )
        .padding(.top, 24)
        .padding(.horizontal, 24)
    }
}
