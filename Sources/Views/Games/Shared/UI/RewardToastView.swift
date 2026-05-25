import SwiftUI

struct RewardToastView: View {
    let reward: GameReward

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("REWARD EARNED")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    if reward.xp > 0 {
                        Text("+\(reward.xp) XP").foregroundColor(Color(hex: "#00F5FF"))
                    }
                    if reward.coins > 0 {
                        Text("+\(reward.coins) 💰").foregroundColor(Color(hex: "#FFD700"))
                    }
                    if reward.gems > 0 {
                        Text("+\(reward.gems) 💎").foregroundColor(Color(hex: "#00F5FF"))
                    }
                }
                .font(.system(.subheadline, design: .rounded, weight: .bold))
            }

            if let badge = reward.badgeUnlocked {
                Divider().background(Color.white.opacity(0.2))
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEW BADGE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary)
                    Text(badge).font(.caption.bold()).foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color(hex: "#1A1A2E"))
        .cornerRadius(12)
        .neonGlow(color: Color(hex: "#8A2BE2").opacity(0.5))
        .shadow(radius: 10)
    }
}
