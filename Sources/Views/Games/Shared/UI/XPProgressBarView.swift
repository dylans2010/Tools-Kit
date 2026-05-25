import SwiftUI

struct XPProgressBarView: View {
    let currentXP: Int
    let xpToNextLevel: Int
    let level: Int

    private var progress: CGFloat {
        guard xpToNextLevel > 0 else { return 0 }
        return CGFloat(currentXP) / CGFloat(xpToNextLevel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Level \(level)")
                    .font(.caption.bold())
                    .foregroundColor(GamingDesignTokens.accentNeon)
                Spacer()
                Text("\(currentXP) / \(xpToNextLevel) XP")
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.white.opacity(0.7))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [GamingDesignTokens.accentNeon, GamingDesignTokens.accentPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * progress), height: 10)
                        .animation(.easeOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 10)
        }
    }
}
