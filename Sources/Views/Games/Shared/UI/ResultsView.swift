import SwiftUI

struct ResultsView: View {
    let reward: GameReward
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("MISSION COMPLETE")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            RewardToastView(reward: reward)
                .scaleEffect(1.2)

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onBack()
            }) {
                Text("BACK TO BASE")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .onAppear {
            XPEngine.shared.awardXP(amount: reward.xp)
            CurrencyLedger.shared.awardCoins(reward.coins, reason: "Game Completion")
            if reward.gems > 0 {
                CurrencyLedger.shared.awardGems(reward.gems, reason: "Milestone")
            }
        }
    }
}
