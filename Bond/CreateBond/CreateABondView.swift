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
                let bgName = step == 4 ? "bg_Share" : step == 1 ? "bg_Config3" : step == 2 ? "bg_Config2" : "bg_Config1"
                Image(bgName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // ── Layout principal ─────────────────────────────
                VStack(spacing: 0) {

                    // ── Header: oculto na tela de share ────────────
                    if !isShareStep {
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
                    }

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
                    if isShareStep {
                        // Step 4: tela fixa, sem scroll
                        StepShareView(
                            bondName: bondTitle.trimmingCharacters(in: .whitespaces),
                            inviteCode: generatedCode,
                            maxParticipants: userTier.maxParticipantsAsCreator,
                            copied: $codeCopied
                        )
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Steps 1-3: scroll + dismiss por gesto
                        ScrollView(showsIndicators: false) {
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
                                } else {
                                    StepThreeView(
                                        challenges: $challenges,
                                        newChallenge: $newChallenge,
                                        showAddChallenge: $showAddChallenge
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.bottom, 16)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }

                    // ── Botão continuar/finalizar ───────────────────
                    Button {
                        handleContinue()
                    } label: {
                        ZStack {
                            Image(isShareStep ? "Botao_roxo" : "Botao_continuar")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                            Text(isSavingBond ? "Saving..." : isShareStep ? "Next" : isLastContentStep ? "Let's go!" : "Continue")
                                .font(.app(.balooBold, size: 24))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 76)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
        }
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

#Preview {
    CreateABondView()
}
