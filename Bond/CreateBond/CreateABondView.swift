// CreateABondView.swift
// Bond

import SwiftUI

struct CreateABondView: View {

    @Environment(\.dismiss) private var dismiss
    var onComplete: (BondModel) -> Void = { _ in }

    /// Códigos já existentes para garantir unicidade local
    var existingCodes: Set<String> = []

    @State private var step: Int = 1
    let totalSteps: Int = 4

    // ── Step 1 ───────────────────────────────────────────────────
    @State private var bondTitle: String = ""
    @State private var durationIndex: Double = 0   // índice em [7,15,30,60,90]

    // ── Step 2 ───────────────────────────────────────────────────
    @State private var bondDescription: String = ""
    @State private var reward: String = ""

    // ── Step 3 ───────────────────────────────────────────────────
    @State private var challenges: [String] = []
    @State private var newChallenge: String = ""
    @State private var showAddChallenge: Bool = false

    // ── Step 4 ───────────────────────────────────────────────────
    @State private var generatedCode: String = ""
    @State private var codeCopied: Bool = false

    // Snap points do slider
    let durationOptions = [7, 15, 30, 60, 90]
    var durationDays: Int { durationOptions[Int(durationIndex)] }

    // Tier do usuário atual
    private var userTier: UserTier { UserManager.shared.tier }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                Color.white.ignoresSafeArea()

                // ── Imagem decorativa do fundo (por step) ──
                Group {
                    if step == 1 { Image("sheet_1") }
                    if step == 2 { Image("sheet_2") }
                    if step == 3 { Image("sheet_3") }
                    if step == 4 { Image("sheet_3") }   // reutiliza sheet_3
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // ── Layout principal ─────────────────────────────
                VStack(spacing: 0) {

                    // ── Header: ícone + título ──────────────────
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))
                        Text("Settings")
                            .font(.app(.balooBold, size: 20))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 20)

                    // ── Progress bar ────────────────────────────
                    GeometryReader { bar in
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
                                    width: bar.size.width * (CGFloat(step) / CGFloat(totalSteps)),
                                    height: 10
                                )
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                        }
                    }
                    .frame(height: 10)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // ── Conteúdo da etapa ───────────────────────
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            if step == 1 {
                                StepOneView(
                                    bondTitle: $bondTitle,
                                    durationIndex: $durationIndex,
                                    durationOptions: durationOptions,
                                    durationDays: durationDays
                                )
                            } else if step == 2 {
                                StepTwoView(
                                    bondDescription: $bondDescription,
                                    reward: $reward
                                )
                            } else if step == 3 {
                                StepThreeView(
                                    challenges: $challenges,
                                    newChallenge: $newChallenge,
                                    showAddChallenge: $showAddChallenge
                                )
                            } else {
                                StepFourView(
                                    bondName: bondTitle.trimmingCharacters(in: .whitespaces),
                                    inviteCode: generatedCode,
                                    maxParticipants: userTier.maxParticipantsAsCreator,
                                    copied: $codeCopied
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                    .onChange(of: step) { _, newStep in
                        // Gera o código ao entrar no step 4
                        if newStep == 4 && generatedCode.isEmpty {
                            generatedCode = Self.generateCode(avoiding: existingCodes)
                        }
                    }

                    // ── Botões fixos na base do VStack ───────────
                    HStack(spacing: 16) {

                        // Botão Voltar
                        Button {
                            if step > 1 {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { step -= 1 }
                            } else {
                                dismiss()
                            }
                        } label: {
                            ZStack {
                                Image("Botao_voltar")
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)

                        // Botão Continuar / Criar / Concluir
                        Button {
                            if step < totalSteps {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { step += 1 }
                            } else {
                                // Step 4 → cria o Bond com o código gerado
                                var newBond = BondModel(
                                    name: bondTitle.trimmingCharacters(in: .whitespaces),
                                    bondDescription: bondDescription,
                                    reward: reward,
                                    challenges: challenges,
                                    duration: durationDays
                                )
                                newBond.inviteCode = generatedCode
                                newBond.maxParticipants = userTier.maxParticipantsAsCreator
                                newBond.memberCount = 1
                                onComplete(newBond)
                                dismiss()
                            }
                        } label: {
                            ZStack {
                                Image("Botao_continuar")
                                    .frame(maxWidth: .infinity)
                                Text(step < 4 ? "Continue" : "Let's go!")
                                    .font(.app(.balooBold, size: 20))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .opacity(step == 1 && bondTitle.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                        .disabled(step == 1 && bondTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 306)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .environment(\.colorScheme, .light)
    }

    // ── Gerador de código único ──────────────────────────────────
    static func generateCode(avoiding existing: Set<String>) -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        var code: String
        repeat {
            code = String((0..<6).map { _ in chars.randomElement()! })
        } while existing.contains(code)
        return code
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Step 4: Código de Convite
// ─────────────────────────────────────────────────────────────────
struct StepFourView: View {
    let bondName: String
    let inviteCode: String
    let maxParticipants: Int
    @Binding var copied: Bool

    var body: some View {
        VStack(spacing: 28) {

            // Título
            VStack(spacing: 4) {
                Text("Your Bond is Ready!")
                    .font(.app(.balooBold, size: 24))
                    .foregroundColor(.black)
                Text("Share the code below with your team")
                    .font(.app(.balooMedium, size: 14))
                    .foregroundColor(.black.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Card do código
            VStack(spacing: 12) {

                Text("INVITE CODE")
                    .font(.app(.balooMedium, size: 12))
                    .foregroundColor(.black.opacity(0.4))
                    .kerning(2)

                Text(inviteCode)
                    .font(.app(.balooBold, size: 46))
                    .kerning(10)
                    .foregroundColor(.black)

                // Capacidade
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.4))
                    Text("Up to \(maxParticipants) members")
                        .font(.app(.balooMedium, size: 13))
                        .foregroundColor(.black.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 6)
            )

            // Botão copiar
            Button {
                UIPasteboard.general.string = inviteCode
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { copied = false }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .semibold))
                    Text(copied ? "Copied!" : "Copy Code")
                        .font(.app(.balooBold, size: 16))
                }
                .foregroundColor(Color(red: 0.42, green: 0.35, blue: 0.80))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.42, green: 0.35, blue: 0.80), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            // Nota de case insensitive
            Text("The code is case insensitive — BOND12 = bond12")
                .font(.app(.balooMedium, size: 12))
                .foregroundColor(.black.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: - Step 1: Título + Duração
// ─────────────────────────────────────────────────────────────────
struct StepOneView: View {
    @Binding var bondTitle: String
    @Binding var durationIndex: Double
    let durationOptions: [Int]
    let durationDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // ── Title ──
            VStack(alignment: .leading, spacing: 10) {
                Text("Title")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)

                ZStack {
                    Image("Botao_branco")

                    HStack {
                        TextField("Bond name:", text: $bondTitle)
                            .font(.app(.balooMedium, size: 18))
                            .foregroundColor(.black.opacity(0.6))
                            .autocorrectionDisabled()
                            .padding(.leading, 20)

                        Image(systemName: "smiley")
                            .foregroundColor(.black.opacity(0.4))
                            .padding(.trailing, 40)
                    }
                }
                .frame(height: 56)
            }

            // ── Duration ──
            VStack(alignment: .leading, spacing: 10) {
                Text("Duration")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)

                Text("\(durationDays) days")
                    .font(.app(.balooMedium, size: 14))
                    .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))

                Slider(value: $durationIndex, in: 0...Double(durationOptions.count - 1), step: 1)
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

                // Labels dos pontos de parada
                HStack {
                    ForEach(durationOptions, id: \.self) { val in
                        Text("\(val)")
                            .font(.app(.balooMedium, size: 11))
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))
                        if val != durationOptions.last { Spacer() }
                    }
                }
            }
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
        VStack(alignment: .leading, spacing: 24) {

            // ── Description ──
            VStack(alignment: .leading, spacing: 10) {
                Text("Description")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)

                ZStack(alignment: .topLeading) {
                    Image("AboutSection")
                        .frame(maxWidth: .infinity)

                    if bondDescription.isEmpty {
                        Text("Describe your Bond...")
                            .font(.app(.balooMedium, size: 15))
                            .foregroundColor(.black.opacity(0.3))
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $bondDescription)
                        .font(.app(.balooMedium, size: 15))
                        .foregroundColor(.black.opacity(0.7))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }
                .clipped()
            }

            // ── Reward ──
            VStack(alignment: .leading, spacing: 10) {
                Text("Reward")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)

                ZStack {
                    Image("Botao_cinza")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)

                    TextField("What's the prize?", text: $reward)
                        .font(.app(.balooMedium, size: 16))
                        .foregroundColor(.black.opacity(0.6))
                        .autocorrectionDisabled()
                        .padding(.horizontal, 20)
                }
                .frame(height: 52)
            }
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
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Challenges")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)
                Text("(optional)")
                    .font(.app(.balooMedium, size: 13))
                    .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))
            }

            // Chips dos challenges
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

            // Input de novo challenge
            if showAddChallenge {
                HStack(spacing: 10) {
                    ZStack {
                        Image("Botao_cinza")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)

                        TextField("New challenge...", text: $newChallenge)
                            .font(.app(.balooMedium, size: 15))
                            .foregroundColor(.black.opacity(0.6))
                            .autocorrectionDisabled()
                            .padding(.horizontal, 20)
                    }
                    .frame(height: 48)

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
// MARK: - Flow Layout
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
