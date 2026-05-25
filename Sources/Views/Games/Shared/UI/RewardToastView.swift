import SwiftUI

struct RewardToastView: View {
    let reward: GameReward
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title3)
                .foregroundColor(GamingDesignTokens.accentGold)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rewards Earned!")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    if reward.xp > 0 {
                        Label("\(reward.xp) XP", systemImage: "bolt.fill")
                            .font(.caption2)
                            .foregroundColor(GamingDesignTokens.accentNeon)
                    }
                    if reward.coins > 0 {
                        Label("\(reward.coins)", systemImage: "dollarsign.circle.fill")
                            .font(.caption2)
                            .foregroundColor(GamingDesignTokens.accentGold)
                    }
                    if reward.gems > 0 {
                        Label("\(reward.gems)", systemImage: "diamond.fill")
                            .font(.caption2)
                            .foregroundColor(GamingDesignTokens.accentPurple)
                    }
                }
            }

            if let badge = reward.badgeUnlocked {
                VStack {
                    Image(systemName: "medal.fill")
                        .foregroundColor(GamingDesignTokens.accentGold)
                    Text(badge)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(GamingDesignTokens.cardSurface)
                .shadow(color: GamingDesignTokens.accentGold.opacity(0.3), radius: 10)
        )
        .offset(y: isVisible ? 0 : -80)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}
