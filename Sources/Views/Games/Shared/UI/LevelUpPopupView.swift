import SwiftUI

struct LevelUpPopupView: View {
    let level: Int
    let bonusCoins: Int
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 20) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(GamingDesignTokens.accentGold)
                    .modifier(PulseAnimationModifier())

                Text("LEVEL UP!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("Level \(level)")
                    .font(.title.bold())
                    .foregroundColor(GamingDesignTokens.accentNeon)

                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(GamingDesignTokens.accentGold)
                    Text("+\(bonusCoins) Bonus Coins")
                        .font(.headline)
                        .foregroundColor(GamingDesignTokens.accentGold)
                }

                Button("Continue") {
                    onDismiss()
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(GamingDesignTokens.accentGold, in: Capsule())
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(GamingDesignTokens.cardSurface)
                    .neonGlow(color: GamingDesignTokens.accentGold)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
