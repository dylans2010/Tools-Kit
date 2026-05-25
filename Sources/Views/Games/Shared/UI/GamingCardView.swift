import SwiftUI

struct GamingDesignTokens {
    static let background       = Color(red: 13/255, green: 13/255, blue: 26/255)
    static let cardSurface      = Color(red: 26/255, green: 26/255, blue: 46/255)
    static let accentGold       = Color(red: 255/255, green: 215/255, blue: 0/255)
    static let accentNeon       = Color(red: 0/255, green: 245/255, blue: 255/255)
    static let accentPurple     = Color(red: 138/255, green: 43/255, blue: 226/255)
    static let dangerRed        = Color(red: 255/255, green: 59/255, blue: 48/255)
    static let successGreen     = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let fontPrimary      = Font.system(.headline, design: .rounded, weight: .bold)
    static let fontMono         = Font.system(.body, design: .monospaced)
}

struct GamingCardView: View {
    let game: GameDefinition
    let highScore: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: game.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: game.accentColorHex))
                    Spacer()
                    Text(game.category.filterLabel)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: game.accentColorHex).opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundColor(Color(hex: game.accentColorHex))
                }

                Text(game.title)
                    .font(GamingDesignTokens.fontPrimary)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(game.shortDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)

                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundColor(GamingDesignTokens.accentGold)
                    Text("\(highScore)")
                        .font(GamingDesignTokens.fontMono)
                        .foregroundColor(GamingDesignTokens.accentGold)
                        .contentTransition(.numericText())
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(GamingDesignTokens.cardSurface)
                    .shadow(color: Color(hex: game.accentColorHex).opacity(0.3), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}
