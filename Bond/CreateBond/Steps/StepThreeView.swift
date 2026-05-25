// StepThreeView.swift
// Bond

import SwiftUI

// ─────────────────────────────────────────────────────────────────
// MARK: - Step 3: Challenges
// ─────────────────────────────────────────────────────────────────
struct StepThreeView: View {
    @Binding var challenges: [String]
    @Binding var newChallenge: String
    @Binding var showAddChallenge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Challenges")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)
                Text("(optional)")
                    .font(.app(.balooMedium, size: 13))
                    .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))
            }

            if !challenges.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(challenges, id: \.self) { challenge in
                        ChallengeChip(title: challenge) {
                            challenges.removeAll { $0 == challenge }
                        }
                    }
                }
            }

            Button {
                withAnimation { showAddChallenge.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("add challenge")
                        .font(.app(.balooMedium, size: 15))
                }
                .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.75))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.35, green: 0.25, blue: 0.75), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            if showAddChallenge {
                HStack(spacing: 10) {
                    ZStack {
                        Image("Botao_branco")

                        TextField("New challenge...", text: $newChallenge)
                            .font(.app(.balooMedium, size: 15))
                            .foregroundColor(.black.opacity(0.6))
                            .autocorrectionDisabled()
                            .padding(.horizontal, 20)
                            .padding(.leading, 40)
                    }
                    .frame(height: 52)

                    Button {
                        let t = newChallenge.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty {
                            withAnimation { challenges.append(t) }
                            newChallenge = ""
                            showAddChallenge = false
                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.75))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
