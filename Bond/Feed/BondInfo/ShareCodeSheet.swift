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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Fundo adaptativo: branco no light mode, preto no dark mode
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

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
}
