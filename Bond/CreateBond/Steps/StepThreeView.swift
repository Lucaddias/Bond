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

    @State private var showChallengeSheet = false

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

            // ── Chips das challenges selecionadas ──────────────────
            if !challenges.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(challenges, id: \.self) { challenge in
                        ChallengeChip(title: challenge) {
                            withAnimation { challenges.removeAll { $0 == challenge } }
                        }
                    }
                }
            }

            // ── Botão abre sheet ───────────────────────────────────
            Button {
                showChallengeSheet = true
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
        }
        .sheet(isPresented: $showChallengeSheet) {
            ChallengePickerSheet(selectedChallenges: $challenges)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.white)
                .interactiveDismissDisabled(false)
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Challenge Picker Sheet
// ─────────────────────────────────────────────────────────────────
struct ChallengePickerSheet: View {
    @Binding var selectedChallenges: [String]
    @Environment(\.dismiss) private var dismiss

    @State private var customText = ""
    @State private var showCustomInput = false

    private let purple = Color(red: 0.35, green: 0.25, blue: 0.75)

    // ── Desafios pré-definidos ─────────────────────────────────────
    let presets: [String] = [
        "Tuesday challenge",
        "Wake up pic",
        "Double photo",
        "Photo with stranger",
        "Daily story",
        "Lunch photo",
        "Group selfie",
        "Outfit of the day",
        "Meme of the week",
        "Night check-in",
        "Surprise photo",
        "15s video",
        "Mandatory smile",
        "Creative pose",
        "Noon shout",
        "Mirror selfie",
        "Thumbs up",
        "Food photo",
        "Dance in public",
        "Feet photo",
        "Ugly face post",
        "No filter photo",
        "3s video",
        "Hashtag of the day",
    ]

    // Selecionados primeiro, depois os não selecionados
    private var orderedPresets: [String] {
        let selected   = presets.filter {  selectedChallenges.contains($0) }
        let unselected = presets.filter { !selectedChallenges.contains($0) }
        return selected + unselected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ─────────────────────────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Challenges")
                        .font(.app(.balooBold, size: 22))
                        .foregroundStyle(.primary)
                    if !selectedChallenges.isEmpty {
                        Text("\(selectedChallenges.count) selecionado\(selectedChallenges.count > 1 ? "s" : "")")
                            .font(.app(.balooMedium, size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // ── Chips ──────────────────────────────────────────────
            ScrollView(showsIndicators: false) {

                FlowLayout(spacing: 10) {

                    // Desafios (selecionados primeiro)
                    ForEach(orderedPresets, id: \.self) { preset in
                        let isSelected = selectedChallenges.contains(preset)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected {
                                    selectedChallenges.removeAll { $0 == preset }
                                } else {
                                    selectedChallenges.append(preset)
                                }
                            }
                        } label: {
                            Text(preset)
                                .font(.app(.balooMedium, size: 14))
                                .foregroundColor(isSelected ? .white : purple)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(isSelected ? purple : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(purple, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
                    }

                    // ── Último item: add challenge ─────────────────
                    if showCustomInput {
                        HStack(spacing: 8) {
                            TextField("Novo desafio...", text: $customText)
                                .font(.app(.balooMedium, size: 14))
                                .foregroundColor(purple)
                                .autocorrectionDisabled()
                                .frame(minWidth: 100)
                            Button {
                                let t = customText.trimmingCharacters(in: .whitespaces)
                                guard !t.isEmpty else { return }
                                withAnimation {
                                    selectedChallenges.append(t)
                                    customText = ""
                                    showCustomInput = false
                                }
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(purple)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(purple, lineWidth: 1.5)
                        )
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showCustomInput = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("add challenge")
                                    .font(.app(.balooMedium, size: 14))
                            }
                            .foregroundColor(purple)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(purple, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.white)
    }
}
