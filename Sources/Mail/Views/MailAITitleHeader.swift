import SwiftUI

struct MailAITitleHeader: View {
    let title: String
    let subtitle: String
    var symbol: String = "apple.intelligence"
    var symbolSize: CGFloat = 18

    var body: some View {
        VStack(spacing: 8) {
            TimelineView(.animation) { timeline in
                let palette = sevenColorGradientPalette(for: timeline.date.timeIntervalSinceReferenceDate)
                let titleGradient = LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)

                HStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: symbolSize, weight: .semibold))
                        .foregroundStyle(titleGradient)

                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(titleGradient)
                }
                .shadow(color: .cyan.opacity(0.22), radius: 10, y: 3)
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func sevenColorGradientPalette(for phase: TimeInterval) -> [Color] {
        let variants: [[Color]] = [
            [.red, .orange, .yellow, .green, .mint, .blue, .purple],
            [.pink, .red, .orange, .yellow, .teal, .blue, .indigo],
            [.cyan, .mint, .green, .yellow, .orange, .pink, .purple]
        ]
        let index = Int((phase / 2.0).rounded(.down)) % variants.count
        return variants[index]
    }
}
