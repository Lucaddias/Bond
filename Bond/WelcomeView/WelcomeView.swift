// WelcomeView.swift
// Bond

import SwiftUI

struct WelcomeView: View {
    @Binding var bonds: [BondModel]
    var onCreateTeam: () -> Void = {}
    @State private var code: String = ""
    @State private var joinError: JoinError? = nil

    enum JoinError: LocalizedError {
        case bondNotFound
        case bondFull
        case limitReached
        case alreadyMember

        var errorDescription: String? {
            switch self {
            case .bondNotFound:  return "Bond not found. Check the code and try again."
            case .bondFull:      return "This Bond is full and can't accept new members."
            case .limitReached:  return "You've reached your Bond limit. Upgrade to Premium for more."
            case .alreadyMember: return "You're already a member of this Bond."
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .top) {

                // ── 1. Background ──
                Image("bg_Welcome")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .ignoresSafeArea()

                // ── 2. Título centralizado em Porkys ──
                VStack(alignment: .center, spacing: -42) {
                    Text("welcome to")
                        .font(.app(.porkysHeavy, size: 54))
                        .foregroundStyle(.black)
                        .kerning(3)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text("Bond")
                        .font(.app(.porkysHeavy, size: 115))
                        .foregroundStyle(.black)
                        .kerning(0)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                }
                .padding(.top, 25)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, geo.safeAreaInsets.top + 90)

                // ── 3. Botões dentro do card branco ──
                VStack(spacing: 10) {

                    // Create Team
                    Button(action: onCreateTeam) {
                        ZStack {
                            Image("Botao_roxo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 315, height: 100)

                            Text("Create Team")
                                .font(.app(.balooBold, size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(height: h * 0.068)

                    // "or"
                    Text("or")
                        .font(.app(.balooBold, size: 36))
                        .foregroundColor(.black.opacity(0.5))

                    // Enter code — campo de texto com fundo cinza
                    ZStack {
                        Image("Botao_cinza")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 315, height: 100)

                        TextField("Enter code", text: $code)
                            .font(.app(.balooBold, size: 26))
                            .foregroundColor(.black)
                            .tint(.black)
                            .multilineTextAlignment(.center)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .submitLabel(.join)
                            .onSubmit { attemptJoin() }
                            .onChange(of: code) { _, new in
                                joinError = nil
                                let filtered = new.filter { $0.isLetter || $0.isNumber }
                                if filtered.count > 6 {
                                    code = String(filtered.prefix(6))
                                } else {
                                    code = filtered
                                }
                            }
                            .padding(.horizontal, 24)
                    }
                    .frame(height: h * 0.068)
                }
                .environment(\.colorScheme, .light)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
                .offset(y: h * 0.695)

                // ── 4. Mão por cima de tudo (último no ZStack) ──
                Image("HandView")
                    .resizable()
                    .scaledToFit()
                    .frame(width: w * 1.13)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, -w * 0.04)
                    .offset(x: -70, y: 340)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        .alert(
            "Can't join Bond",
            isPresented: Binding(get: { joinError != nil }, set: { if !$0 { joinError = nil } }),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(joinError?.errorDescription ?? "") }
        )
    }

    // ── Lógica de join ───────────────────────────────────────────
    private func attemptJoin() {
        let input = code.uppercased()
        guard input.count == 6 else { return }

        // 1. Usuário já está no limite de Bonds?
        guard UserManager.shared.canJoinOrCreateBond(currentCount: bonds.count) else {
            joinError = .limitReached; return
        }

        // 2. Existe um Bond com esse código? (busca local; CloudKit substituirá)
        guard let idx = bonds.firstIndex(where: { $0.inviteCode.uppercased() == input }) else {
            joinError = .bondNotFound; return
        }

        // 3. Usuário já é membro?
        // (Por ora verificamos se o Bond já está na lista local)
        // Quando CloudKit estiver integrado, verificaremos BondMembership
        joinError = .alreadyMember
        // Quando cloudKit integrado: verificar capacidade e adicionar membro
        // guard bonds[idx].memberCount < bonds[idx].maxParticipants else {
        //     joinError = .bondFull; return
        // }
        // bonds[idx].memberCount += 1
    }
}

#Preview {
    WelcomeView(bonds: .constant([]))
}
