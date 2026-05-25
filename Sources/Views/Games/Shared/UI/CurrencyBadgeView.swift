import SwiftUI

struct CurrencyBadgeView: View {
    let amount: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .shimmer()
            Text("\(amount)")
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}
