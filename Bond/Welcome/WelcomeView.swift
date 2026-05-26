// WelcomeView.swift
// Bond

import SwiftUI

struct WelcomeView: View {
    @Binding var bonds: [BondModel]
    var onCreateTeam: () -> Void = {}
    @State private var code: String = ""
    @State private var joinError: JoinError? = nil
    @State private var keyboardHeight: CGFloat = 0

    enum JoinError: LocalizedError {
        case bondNotFound
        case bondFull
        case limitReached
        case alreadyMember
        case iCloudUnavailable
        case networkUnavailable
        case generic(String)

        var errorDescription: String? {
            switch self {
            case .bondNotFound:      return "Bond not found. Check the code and try again."
            case .bondFull:          return "This Bond is full and can't accept new members."
            case .limitReached:      return "You've reached your Bond limit. Upgrade to Premium for more."
            case .alreadyMember:     return "You're already a member of this Bond."
            case .iCloudUnavailable: return "iCloud is not available. Sign in to iCloud in Settings and try again."
            case .networkUnavailable:return "No internet connection. Check your network and try again."
            case .generic(let message): return message
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

                // ── 2. Título + Botões (sobem juntos com o teclado) ──
                VStack(spacing: 0) {

                    // Título
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
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer()

                    // Botões
                    VStack(spacing: 10) {

                        // Enter code
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

                        // "or"
                        Text("or")
                            .font(.app(.balooBold, size: 36))
                            .foregroundColor(.black.opacity(0.5))

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
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 60)
                }
                .environment(\.colorScheme, .light)
                .frame(maxWidth: .infinity)
                .padding(.top, geo.safeAreaInsets.top + 90)
                .frame(height: h)

                // ── 4. Mão por cima de tudo ──
                // ─── Ajuste de posição por dispositivo ───────────────
                // iPhone 17 Pro Max: largura > 420pt
                // iPhone 17 Pro    : largura ≤ 420pt
                let isProMax = w > 420
                let handOffsetX: CGFloat = isProMax ? -90  : -70   // Pro Max : Pro
                let handOffsetY: CGFloat = isProMax ? 390  : 340   // Pro Max : Pro
                // ─────────────────────────────────────────────────────

                Image("HandView")
                    .resizable()
                    .scaledToFit()
                    .frame(width: w * 1.13)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, -w * 0.04)
                    .offset(x: handOffsetX, y: handOffsetY)
            }
            .frame(width: w, height: h)
            .offset(y: -keyboardHeight * 0.45)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: keyboardHeight)
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { n in
            if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .alert(
            "Can't join Bond",
            isPresented: Binding(get: { joinError != nil }, set: { if !$0 { joinError = nil } }),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(joinError?.errorDescription ?? "") }
        )
    }

    private func attemptJoin() {
        let input = code.uppercased()
        guard input.count == 6 else { return }

        Task {
            do {
                let bond = try await CloudKitManager.shared.joinBond(
                    code: input,
                    currentBondCount: bonds.count
                )
                bonds.append(bond)
                code = ""
            } catch let e as CloudKitError {
                switch e {
                case .bondNotFound:      joinError = .bondNotFound
                case .bondFull:          joinError = .bondFull
                case .alreadyMember:     joinError = .alreadyMember
                case .iCloudNotAvailable: joinError = .iCloudUnavailable
                case .networkUnavailable: joinError = .networkUnavailable
                default:
                    joinError = .generic(e.errorDescription ?? "Failed to join Bond.")
                }
            } catch {
                joinError = .generic(error.localizedDescription)
            }
        }
    }
}

#Preview {
    WelcomeView(bonds: .constant([]))
}
