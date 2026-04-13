import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    var backgroundColor: Color = Color(.secondarySystemBackground)
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 4

    init(backgroundColor: Color = Color(.secondarySystemBackground),
         cornerRadius: CGFloat = 16,
         shadowRadius: CGFloat = 4,
         @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: shadowRadius, x: 0, y: 2)
    }
}
