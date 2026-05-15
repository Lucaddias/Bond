// CreateABondView.swift
// Bond

import SwiftUI

struct CreateABondView: View {

    @Environment(\.dismiss) private var dismiss
    var onComplete: (BondModel) -> Void = { _ in }

    @State private var step: Int = 1
    let totalSteps: Int = 3

    // ── Step 1 ───────────────────────────────────────────────────
    @State private var bondTitle: String = ""
    @State private var duration: Double = 0

    // ── Step 2 ───────────────────────────────────────────────────
    @State private var bondDescription: String = ""
    @State private var reward: String = ""

    // ── Step 3 ───────────────────────────────────────────────────
    @State private var challenges: [String] = []
    @State private var newChallenge: String = ""
    @State private var showAddChallenge: Bool = false

    var body: some View {
        ZStack(alignment: .top) {

            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header: título + progress bar ───────────────
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))

                        Text("Settings")
                            .font(.app(.balooBold, size: 20))
                            .foregroundColor(.black)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.80, green: 0.80, blue: 0.82))
                                .frame(height: 10)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.45, blue: 0.10),
                                            Color(red: 1.0, green: 0.85, blue: 0.10)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geo.size.width * (CGFloat(step) / CGFloat(totalSteps)),
                                    height: 10
                                )
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // ── Conteúdo por etapa ───────────────────────────
                ZStack {
                    if step == 1 { StepOneView(bondTitle: $bondTitle, duration: $duration) }
                    if step == 2 { StepTwoView(bondDescription: $bondDescription, reward: $reward) }
                    if step == 3 {
                        StepThreeView(
                            challenges: $challenges,
                            newChallenge: $newChallenge,
                            showAddChallenge: $showAddChallenge
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Botões voltar / continuar ────────────────────
                HStack(spacing: 16) {
                    Button {
                        if step > 1 {
                            withAnimation { step -= 1 }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image("Botao_voltar")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if step < totalSteps {
                            withAnimation { step += 1 }
                        } else {
                            let newBond = BondModel(
                                name: bondTitle.trimmingCharacters(in: .whitespaces),
                                bondDescription: bondDescription,
                                reward: reward,
                                challenges: challenges,
                                duration: Int(duration)
                            )
                            onComplete(newBond)
                            dismiss()
                        }
                    } label: {
                        Image("Botao_continuar")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(.plain)
                    .disabled(step == 1 && bondTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Step 1: Título + Duração
// ─────────────────────────────────────────────────────────────────
struct StepOneView: View {
    @Binding var bondTitle: String
    @Binding var duration: Double

    var durationLabel: String {
        let days = Int(duration)
        return days == 0 ? "0 days" : "\(days) day\(days == 1 ? "" : "s")"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("sheet_1")
            VStack(alignment: .leading, spacing: 20) {

                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.app(.balooBold, size: 20))
                        .foregroundColor(.black)

                    ZStack {
                        Image("Botao_branco")

                        HStack {
                            TextField("", text: $bondTitle)
                                .font(.app(.balooMedium, size: 18))
                                .foregroundColor(.black.opacity(0.6))
                                .autocorrectionDisabled()
                                .padding(.leading, 20)

                            Image(systemName: "smiley")
                                .foregroundColor(.black.opacity(0.5))
                                
                                .padding(.trailing, 26)
                        }
                        .frame(height: 56)
                    }
                }

                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration")
                        .font(.app(.balooBold, size: 20))
                        .foregroundColor(.black)

                    Text(durationLabel)
                        .font(.app(.balooMedium, size: 14))
                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))

                    Slider(value: $duration, in: 0...90, step: 1)
                        .tint(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.45, blue: 0.10),
                                    Color(red: 1.0, green: 0.85, blue: 0.10)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Step 2: Descrição + Recompensa
// ─────────────────────────────────────────────────────────────────
struct StepTwoView: View {
    @Binding var bondDescription: String
    @Binding var reward: String

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("sheet_2")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 20) {

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.app(.balooBold, size: 20))
                        .foregroundColor(.black)

                    Image("AboutSection")
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .topLeading) {
                            if bondDescription.isEmpty {
                                Text("Describe your Bond...")
                                    .font(.app(.balooMedium, size: 15))
                                    .foregroundColor(.black.opacity(0.3))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 14)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $bondDescription)
                                .font(.app(.balooMedium, size: 15))
                                .foregroundColor(.black.opacity(0.7))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .padding(.horizontal, 12)
                                .padding(.top, 6)
                        }
                        .clipped()
                }

                // Reward
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reward")
                        .font(.app(.balooBold, size: 20))
                        .foregroundColor(.black)

                    ZStack {
                        Image("Botao_cinza")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)

                        TextField("", text: $reward)
                            .font(.app(.balooMedium, size: 16))
                            .foregroundColor(.black.opacity(0.6))
                            .autocorrectionDisabled()
                            .padding(.horizontal, 20)
                            .frame(height: 50)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Step 3: Challenges
// ─────────────────────────────────────────────────────────────────
struct StepThreeView: View {
    @Binding var challenges: [String]
    @Binding var newChallenge: String
    @Binding var showAddChallenge: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("sheet_3")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 16) {

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Challenges")
                        .font(.app(.balooBold, size: 20))
                        .foregroundColor(.black)
                    Text("(optional)")
                        .font(.app(.balooMedium, size: 13))
                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))
                }

                // Chips dos challenges selecionados
                if !challenges.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(challenges, id: \.self) { challenge in
                            ChallengeChip(title: challenge) {
                                challenges.removeAll { $0 == challenge }
                            }
                        }
                    }
                }

                // Botão + add challenge
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

                // Painel de input
                if showAddChallenge {
                    HStack(spacing: 10) {
                        ZStack {
                            Image("Botao_cinza")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)

                            TextField("New challenge...", text: $newChallenge)
                                .font(.app(.balooMedium, size: 15))
                                .foregroundColor(.black.opacity(0.6))
                                .autocorrectionDisabled()
                                .padding(.horizontal, 16)
                                .frame(height: 46)
                        }

                        Button {
                            let trimmed = newChallenge.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                withAnimation { challenges.append(trimmed) }
                                newChallenge = ""
                                showAddChallenge = false
                            }
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.75))
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Challenge Chip
// ─────────────────────────────────────────────────────────────────
struct ChallengeChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.app(.balooMedium, size: 13))
                .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.75))
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.35, green: 0.25, blue: 0.75))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 0.35, green: 0.25, blue: 0.75), lineWidth: 1.5)
        )
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Flow Layout (chips)
// ─────────────────────────────────────────────────────────────────
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.height }.max() ?? 0 }.reduce(0) { $0 + $1 + spacing }
        return CGSize(width: proposal.width ?? 0, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.height }.max() ?? 0
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private struct Item { let view: LayoutSubview; let size: CGSize; var width: CGFloat { size.width }; var height: CGFloat { size.height } }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Item]] {
        let maxWidth = proposal.width ?? 0
        var rows: [[Item]] = [[]]
        var rowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(Item(view: subview, size: size))
            rowWidth += size.width + spacing
        }
        return rows
    }
}

#Preview {
    CreateABondView()
}
