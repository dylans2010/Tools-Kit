import SwiftUI

struct LevelUpPopupView: View {
    let level: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("LEVEL UP!")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "#FFD700"))
                .shimmer()

            ZStack {
                Circle()
                    .fill(Color(hex: "#8A2BE2"))
                    .frame(width: 120, height: 120)
                    .neonGlow(color: Color(hex: "#8A2BE2"))

                Text("\(level)")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("Rewards Unlocked:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("💰 \(level * 50) Coins")
                    .font(.title3.bold())
                    .foregroundColor(Color(hex: "#FFD700"))
            }

            Button {
                onDismiss()
            } label: {
                Text("AWESOME!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#8A2BE2"), in: Capsule())
            }
            .pulse()
            .hapticTap()
        }
        .padding(40)
        .background(Color(hex: "#1A1A2E"))
        .cornerRadius(30)
        .shadow(radius: 20)
    }
}
