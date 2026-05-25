import SwiftUI

struct HUDOverlayView: View {
    @ObservedObject var ledger: CurrencyLedger
    @ObservedObject var xpEngine: XPEngine

    @State private var displayedCoins: Int = 0
    @State private var displayedGems: Int = 0
    @State private var displayedXP: Int = 0
    @State private var displayedLevel: Int = 1

    var body: some View {
        HStack(spacing: 12) {
            levelBadge
            xpBar
            Spacer()
            currencyBadge(icon: "dollarsign.circle.fill", value: displayedCoins, color: GamingDesignTokens.accentGold)
            currencyBadge(icon: "diamond.fill", value: displayedGems, color: GamingDesignTokens.accentPurple)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(GamingDesignTokens.cardSurface.opacity(0.95))
        .onAppear { syncValues() }
        .onChange(of: ledger.profile) { _, _ in
            withAnimation(.easeOut(duration: 0.4)) { syncValues() }
        }
    }

    private func syncValues() {
        displayedCoins = ledger.profile.coins
        displayedGems = ledger.profile.gems
        displayedXP = ledger.profile.xp
        displayedLevel = ledger.profile.level
    }

    private var levelBadge: some View {
        ZStack {
            Circle()
                .fill(GamingDesignTokens.accentPurple)
                .frame(width: 36, height: 36)
            Text("L\(displayedLevel)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
    }

    private var xpBar: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("XP")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GamingDesignTokens.accentNeon)
                        .frame(width: max(0, geo.size.width * xpFraction))
                        .animation(.easeOut(duration: 0.4), value: xpFraction)
                }
            }
            .frame(height: 6)
        }
        .frame(width: 80)
    }

    private var xpFraction: CGFloat {
        let needed = ledger.profile.xpToNextLevel
        guard needed > 0 else { return 0 }
        return CGFloat(displayedXP) / CGFloat(needed)
    }

    private func currencyBadge(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text("\(value)")
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}
