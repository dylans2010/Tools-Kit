import SwiftUI

struct CurrencyBadgeView: View {
    let icon: String
    let value: Int
    let color: Color

    @State private var displayValue: Int = 0

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
            Text("\(displayValue)")
                .font(GamingDesignTokens.fontMono)
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(GamingDesignTokens.cardSurface, in: Capsule())
        .modifier(ShimmerModifier())
        .onAppear { displayValue = value }
        .onChange(of: value) { _, newVal in
            withAnimation(.easeOut(duration: 0.5)) {
                displayValue = newVal
            }
        }
    }
}
