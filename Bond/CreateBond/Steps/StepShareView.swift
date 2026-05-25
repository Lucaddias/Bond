// StepShareView.swift
// Bond

import SwiftUI
import CoreImage.CIFilterBuiltins

// ─────────────────────────────────────────────────────────────────
// MARK: - Step Share: QR Code + Código de Convite
// ─────────────────────────────────────────────────────────────────
struct StepShareView: View {
    let bondName: String
    let inviteCode: String
    let maxParticipants: Int
    @Binding var copied: Bool

    @State private var showShareSheet = false

    var body: some View {
        GeometryReader { geo in
            // h < 680 → iPhone 16 standard e menores
            // h ≥ 680 → iPhone 16 Pro Max, 17 Pro Max e maiores
            let compact = geo.size.height < 680

            let qrSize:        CGFloat = compact ? 260 : 280
            let titleSize:     CGFloat = compact ? 42  : 52
            let teamCodeSize:  CGFloat = compact ? 35  : 40
            let codeSize:      CGFloat = compact ? 45  : 42
            let topPad:        CGFloat = compact ? 55  : 50
            let vSpacing:      CGFloat = compact ? 10   : 20
            let innerSpacing:  CGFloat = compact ? 10   : 16

            VStack(spacing: vSpacing) {

                // ── Título ──────────────────────────────────────────
                Text("Share code!")
                    .font(.app(.porkysHeavy, size: titleSize))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .kerning(2)

                // ── Conteúdo sobreposto à caixa do bg_Share ──────────
                VStack(spacing: innerSpacing) {
                    // Label
                    Text("Team code")
                        .font(.app(.balooBold, size: teamCodeSize))
                        .foregroundColor(.black.opacity(0.35))
                        .padding(.top, topPad)

                    // QR Code
                    if let qrImage = generateQRCode(from: inviteCode) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: qrSize, height: qrSize)
                    }

                    // Código
                    Text(inviteCode)
                        .font(.app(.balooBold, size: codeSize))
                        .kerning(6)
                        .foregroundColor(.black.opacity(0.45))

                    // ── Botão compartilhar — trailing, dentro da caixa do bg ──
                    HStack {
                        Spacer()
                        Button { showShareSheet = true } label: {
                            Image("Botao_compartilhar")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, -16)
                    .padding(.bottom, 32)
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)

                Spacer()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Join my Bond \"\(bondName)\"! Use the code: \(inviteCode)"])
                .presentationDetents([.medium])
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
