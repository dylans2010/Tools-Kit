import SwiftUI

struct LobbyView: View {
    let title: String
    let gameID: String
    let onStart: () -> Void
    @ObservedObject var ledger = CurrencyLedger.shared

    var body: some View {
        VStack(spacing: 30) {
            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack {
                Text("BEST SCORE")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(ledger.profile.perGameStats[gameID]?.highScore ?? 0)")
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "#FFD700"))
            }

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onStart()
            }) {
                Text("START MISSION")
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#8A2BE2"))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .pulse()
        }
    }
}
