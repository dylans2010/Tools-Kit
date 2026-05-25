import SwiftUI

struct HUDOverlayView: View {
    @ObservedObject var ledger = CurrencyLedger.shared
    @State private var animatedCoins: Int = 0

    var body: some View {
        HStack(spacing: 16) {
            LevelBadgeView(level: ledger.profile.level)

            XPProgressBarView(xp: ledger.profile.xp, total: ledger.profile.xpToNextLevel)

            CurrencyBadgeView(amount: animatedCoins, icon: "circle.fill", color: Color(hex: "#FFD700"))
                .onChange(of: ledger.profile.coins) { _, newValue in
                    withAnimation(.easeOut(duration: 0.5)) {
                        animatedCoins = newValue
                    }
                }

            CurrencyBadgeView(amount: ledger.profile.gems, icon: "diamond.fill", color: Color(hex: "#00F5FF"))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
        .onAppear {
            animatedCoins = ledger.profile.coins
        }
    }
}

struct LevelBadgeView: View {
    let level: Int
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "#8A2BE2"), Color(hex: "#4B0082")], startPoint: .top, endPoint: .bottom))
                .frame(width: 40, height: 40)
            Text("\(level)")
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundColor(.white)
        }
        .neonGlow(color: Color(hex: "#8A2BE2"))
    }
}
