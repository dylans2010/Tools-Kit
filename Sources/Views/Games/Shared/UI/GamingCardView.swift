import SwiftUI

struct GamingCardView: View {
    let game: GameDefinition
    let highScore: Int

    static let background       = Color(hex: "#0D0D1A")
    static let cardSurface      = Color(hex: "#1A1A2E")
    static let accentGold       = Color(hex: "#FFD700")
    static let accentNeon       = Color(hex: "#00F5FF")
    static let accentPurple     = Color(hex: "#8A2BE2")
    static let dangerRed        = Color(hex: "#FF3B30")
    static let successGreen     = Color(hex: "#34C759")
    static let fontPrimary      = Font.system(.headline, design: .rounded, weight: .bold)
    static let fontMono         = Font.system(.body, design: .monospaced)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: game.iconName)
                    .font(.title2)
                    .foregroundColor(GamingCardView.accentNeon)
                    .frame(width: 44, height: 44)
                    .background(GamingCardView.accentNeon.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(GamingCardView.fontPrimary)
                        .foregroundColor(.white)
                    Text(game.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack {
                VStack(alignment: .leading) {
                    Text("HIGH SCORE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary)
                    Text("\(highScore)")
                        .font(GamingCardView.fontMono)
                        .foregroundColor(GamingCardView.accentGold)
                }

                Spacer()

                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(GamingCardView.accentPurple, in: Circle())
            }
        }
        .gamingCard()
        .neonGlow(color: GamingCardView.accentPurple.opacity(0.3))
    }
}
