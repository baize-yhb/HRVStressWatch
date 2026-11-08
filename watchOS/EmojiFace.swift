//
//  EmojiFace.swift
//  watchOS/Views
//

import SwiftUI

struct EmojiFace: View {
    let level: StressLevel
    let customEmoji: String?
    let score: Double?
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var breathPhase: Bool = false

    private var emoji: String { customEmoji ?? level.defaultEmoji }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: level.colorHex).opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 90
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(breathPhase ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: breathPhase)

            Text(emoji)
                .font(.system(size: 100))
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
        }
        .onChange(of: level) { _, _ in
            triggerLevelChangeAnimation()
        }
        .onAppear {
            if (score ?? 0) >= 80 { breathPhase = true }
            triggerLevelChangeAnimation()
        }
    }

    private func triggerLevelChangeAnimation() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            scale = 1.25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
        if level >= .stressed {
            withAnimation(.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)) {
                rotation = 5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                rotation = 0
            }
        }
        breathPhase = (level == .explode)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
