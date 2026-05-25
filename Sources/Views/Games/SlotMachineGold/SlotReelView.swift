import SwiftUI

struct SlotReelView: View {
    let symbols = ["🍒", "🍋", "🔔", "⭐", "7️⃣"]
    @Binding var currentSymbol: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)).frame(width: 80, height: 120)
            Text(currentSymbol).font(.system(size: 40))
        }
    }
}
