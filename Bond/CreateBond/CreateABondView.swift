// CreateABondView.swift
// Bond

import SwiftUI
import CoreImage.CIFilterBuiltins

struct CreateABondView: View {

    @Environment(\.dismiss) private var dismiss
    var onComplete: (BondModel) async throws -> Void = { _ in }
    var existingCodes: Set<String> = []

    @State private var step: Int = 1
    let totalSteps: Int = 3  // barra mostra 3 steps

    // ── Step 1 ───────────────────────────────────────────────────
    @State private var bondTitle: String = ""
    @State private var durationIndex: Double = 0
    @State private var showEmojiPicker: Bool = false

    // ── Step 2 ───────────────────────────────────────────────────
    @State private var bondDescription: String = ""
    @State private var reward: String = ""

    // ── Step 3 ───────────────────────────────────────────────────
    @State private var challenges: [String] = []
    @State private var newChallenge: String = ""
    @State private var showAddChallenge: Bool = false

    // ── Step 4 (compartilhar — fora da barra) ────────────────────
    @State private var generatedCode: String = ""
    @State private var codeCopied: Bool = false
    @State private var isSavingBond: Bool = false
    @State private var saveErrorMessage: String? = nil

    let durationOptions = [7, 15, 30, 60, 90]
    var durationDays: Int { durationOptions[Int(durationIndex)] }

    private var userTier: UserTier { UserManager.shared.tier }
    private var isLastContentStep: Bool { step == totalSteps }
    private var isShareStep: Bool { step == 4 }
    private var continueDisabled: Bool {
        step == 1 && bondTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {

                Color.white.ignoresSafeArea()

                // ── Imagem decorativa do fundo ──
                let bgName = step == 1 ? "bg_Config3" : step == 2 ? "bg_Config2" : "bg_Config1"
                Image(bgName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // ── Layout principal ─────────────────────────────
                VStack(spacing: 0) {

                    // ── Header: botão voltar + título ──────────────
                    ZStack {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.57))
                            Text("Settings")
                                .font(.app(.balooBold, size: 20))
                                .foregroundColor(.black)
                        }

                        HStack {
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
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // ── Progress bar (só para steps 1-3) ───────────
                    if !isShareStep {
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
                                        width: bar.size.width * (CGFloat(min(step, totalSteps)) / CGFloat(totalSteps)),
                                        height: 10
                                    )
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                            }
                        }
                        .frame(height: 10)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    } else {
                        Spacer().frame(height: 32)
                    }

                    // ── Conteúdo da etapa ───────────────────────────
                    Group {
                        if step == 1 {
                            StepOneView(
                                bondTitle: $bondTitle,
                                durationIndex: $durationIndex,
                                showEmojiPicker: $showEmojiPicker,
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
                            StepShareView(
                                bondName: bondTitle.trimmingCharacters(in: .whitespaces),
                                inviteCode: generatedCode,
                                maxParticipants: userTier.maxParticipantsAsCreator,
                                copied: $codeCopied
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    Spacer()

                    // ── Botão continuar/finalizar ───────────────────
                    Button {
                        handleContinue()
                    } label: {
                        ZStack {
                            Image("Botao_continuar")
                                .frame(maxWidth: .infinity)
                            Text(isSavingBond ? "Saving..." : isShareStep ? "Done" : isLastContentStep ? "Let's go!" : "Continue")
                                .font(.app(.balooBold, size: 20))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 40)
                    }
                    .buttonStyle(.plain)
                    .opacity(continueDisabled ? 0.4 : 1)
                    .disabled(continueDisabled || isSavingBond)
                    .padding(.horizontal, 24)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 24)
                }
                .padding(.top, 50)
            }
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .light)
        .alert("Sync Error", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func handleContinue() {
        if isShareStep {
            dismiss()
        } else if isLastContentStep {
            // Gera código e cria o bond
            if generatedCode.isEmpty {
                generatedCode = Self.generateCode(avoiding: existingCodes)
            }
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
            isSavingBond = true
            Task {
                do {
                    try await onComplete(newBond)
                    await MainActor.run {
                        isSavingBond = false
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { step = 4 }
                    }
                } catch {
                    await MainActor.run {
                        isSavingBond = false
                        saveErrorMessage = (error as? CloudKitError)?.errorDescription ?? error.localizedDescription
                    }
                }
            }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { step += 1 }
        }
    }

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
// MARK: - Step 1: Título + Duração
// ─────────────────────────────────────────────────────────────────
struct StepOneView: View {
    @Binding var bondTitle: String
    @Binding var durationIndex: Double
    @Binding var showEmojiPicker: Bool
    let durationOptions: [Int]
    let durationDays: Int

    private let emojis = ["🎨", "🎶", "🧶", "🏋️‍♂️", "📚", "❤️", "🚀", "🎯", "💪", "🏆", "⚡️", "🔥"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // ── Title ──
            VStack(alignment: .leading, spacing: 10) {
                Text("Title")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)
                    .padding(.leading, 40)

                ZStack {
                    Image("Botao_branco")

                    HStack {
                        TextField("Bond name:", text: $bondTitle)
                            .font(.app(.balooMedium, size: 18))
                            .foregroundColor(.black.opacity(0.6))
                            .autocorrectionDisabled()
                            .padding(.leading, 40)

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showEmojiPicker.toggle()
                            }
                        } label: {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 22))
                                .foregroundColor(showEmojiPicker
                                    ? Color(red: 0.42, green: 0.35, blue: 0.80)
                                    : .black.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 40)
                    }
                }
                .frame(height: 56)

                // ── Emoji picker ──
                if showEmojiPicker {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button {
                                    bondTitle += emoji
                                    showEmojiPicker = false
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 28))
                                        .padding(6)
                                        .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
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
                    .padding(.leading, 40)

                ZStack(alignment: .topLeading) {
                    Image("AboutSection")
                        .frame(maxWidth: .infinity)

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
                        .padding(.leading, 20)
                }
                .clipped()
            }

            // ── Reward ──
            VStack(alignment: .leading, spacing: 10) {
                Text("Reward")
                    .font(.app(.balooBold, size: 20))
                    .foregroundColor(.black)
                    .padding(.leading, 40)

                ZStack {
                    Image("Botao_branco")

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

// ─────────────────────────────────────────────────────────────────
// MARK: - Step Share: QR Code + Código de Convite
// ─────────────────────────────────────────────────────────────────
struct StepShareView: View {
    let bondName: String
    let inviteCode: String
    let maxParticipants: Int
    @Binding var copied: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // QR Code
            if let qrImage = generateQRCode(from: inviteCode) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // Código em texto
            VStack(spacing: 6) {
                Text("INVITE CODE")
                    .font(.app(.balooMedium, size: 11))
                    .foregroundColor(.black.opacity(0.4))
                    .kerning(2)

                Text(inviteCode)
                    .font(.app(.balooBold, size: 44))
                    .kerning(8)
                    .foregroundColor(.black)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.35))
                    Text("Up to \(maxParticipants) members")
                        .font(.app(.balooMedium, size: 13))
                        .foregroundColor(.black.opacity(0.35))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.97, green: 0.97, blue: 0.99))
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
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
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
#Preview("Step 1") {
    StepOneView(
        bondTitle: .constant("Summer Squad"),
        durationIndex: .constant(1),
        showEmojiPicker: .constant(false),
        durationOptions: [7, 15, 30, 60, 90],
        durationDays: 15
    )
    .padding(24)
}

#Preview("Step 2") {
    StepTwoView(
        bondDescription: .constant(""),
        reward: .constant("")
    )
    .padding(24)
}

#Preview("Step 3") {
    StepThreeView(
        challenges: .constant(["Run 5km", "No sugar"]),
        newChallenge: .constant(""),
        showAddChallenge: .constant(false)
    )
    .padding(24)
}
