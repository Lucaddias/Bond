// WelcomeView.swift
// Bond

import SwiftUI

struct WelcomeView: View {
    var onCreateTeam: () -> Void = {}
    @State private var code: String = ""

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
                        .kerning(3)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text("Bond")
                        .font(.app(.porkysHeavy, size: 115))
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
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.62))

                    // Enter code — campo de texto com fundo cinza
                    ZStack {
                        Image("Botao_cinza")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 315, height: 100)

                        TextField("Enter code", text: $code)
                            .font(.app(.balooBold, size: 26))
                            .foregroundColor(Color(red: 0.40, green: 0.40, blue: 0.42))
                            .multilineTextAlignment(.center)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: code) { _, new in
                                // Limita a 6 caracteres alfanuméricos
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
    }
}

#Preview {
    WelcomeView()
}
