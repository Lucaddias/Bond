// StepTwoView.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Step 2: Descrição + Recompensa
// ─────────────────────────────────────────────────────────────────
struct StepTwoView: View {
    @Binding var bondDescription: String
    @Binding var reward: String
    @Binding var floatField: FloatField?

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
                    } else {
                        Text(bondDescription)
                            .font(.app(.balooMedium, size: 15))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.horizontal, 22)
                            .padding(.top, 16)
                            .padding(.leading, 10)
                            .lineLimit(6)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { floatField = .description }
                .clipped()
                .opacity(floatField == .description ? 0 : 1)
                .animation(.easeInOut(duration: 0.15), value: floatField == .description)
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

                    HStack {
                        Text(reward.isEmpty ? "What's the prize?" : reward)
                            .font(.app(.balooMedium, size: 16))
                            .foregroundColor(reward.isEmpty ? .black.opacity(0.3) : .black.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.leading, 10)
                            .lineLimit(1)
                        Spacer()
                    }
                }
                .frame(height: 56)
                .contentShape(Rectangle())
                .onTapGesture { floatField = .reward }
                .opacity(floatField == .reward ? 0 : 1)
                .animation(.easeInOut(duration: 0.15), value: floatField == .reward)
            }
        }
    }
}
