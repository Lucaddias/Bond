// StepOneView.swift
// Bond

import SwiftUI

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
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                ZStack {
                    Image("Botao_branco")
                        .resizable()
                        .scaledToFill()
                        .padding(.bottom, 20)

                    HStack {
                        TextField("Bond name:", text: $bondTitle)
                            .font(.app(.balooMedium, size: 18))
                            .foregroundColor(.black.opacity(0.6))
                            .autocorrectionDisabled()
                            .padding(.leading, 10)

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
                        .padding(.bottom, 10)
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
                                        .background(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 12)
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
