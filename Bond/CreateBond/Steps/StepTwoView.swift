// StepTwoView.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Step 2: Descrição + Recompensa
// ─────────────────────────────────────────────────────────────────
struct StepTwoView: View {
    @Binding var bondDescription: String
    @Binding var reward: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // ── Description ──
            VStack(alignment: .leading, spacing: 10) {
                Text("Description")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)
                    .padding(.bottom, -17)
                    .padding(.leading, 10)

                ZStack(alignment: .topLeading) {
                    Image("AboutSection")
                        .resizable()
                        .scaledToFill()


                    if bondDescription.isEmpty {
                        Text("Describe your Bond...")
                            .font(.app(.balooMedium, size: 15))
                            .foregroundColor(.black.opacity(0.3))
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.leading, 10)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $bondDescription)
                        .font(.app(.balooMedium, size: 15))
                        .foregroundColor(.black.opacity(0.7))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .frame(height: 130)
                        .padding(.leading, 10)
                }
                .clipped()
            }

            // ── Reward ──
            VStack(alignment: .leading, spacing: 10) {
                Text("Reward")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                    .padding(.leading, 10)

                ZStack {
                    Image("Botao_branco")
                        .resizable()
                        .scaledToFill()


                    TextField("What's the prize?", text: $reward)
                        .font(.app(.balooMedium, size: 16))
                        .foregroundColor(.black.opacity(0.6))
                        .autocorrectionDisabled()
                        .padding(.horizontal, 20)
                        .padding(.leading, 10)
                }
                .frame(height: 56)
            }
        }
    }
}
