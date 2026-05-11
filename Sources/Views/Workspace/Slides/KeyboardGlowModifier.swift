import SwiftUI

/// A view modifier that renders a dynamic, fluid gradient background behind content.
/// Intensity and motion increase when the keyboard is visible.
struct KeyboardGlowModifier: ViewModifier {
    @ObservedObject var keyboard: KeyboardObserver

    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var scale: CGFloat = 1.0

    private var isActive: Bool { keyboard.isVisible }

    private var idleColors: [Color] {
        [
            Color(.systemIndigo).opacity(0.18),
            Color(.systemPurple).opacity(0.14),
            Color(.systemTeal).opacity(0.12)
        ]
    }

    private var activeColors: [Color] {
        [
            Color(.systemIndigo).opacity(0.38),
            Color(.systemPurple).opacity(0.30),
            Color(.systemCyan).opacity(0.26)
        ]
    }

    private var colors: [Color] { isActive ? activeColors : idleColors }

    private var motionRange: CGFloat { isActive ? 30 : 10 }
    private var animationDuration: Double { isActive ? 2.5 : 4.0 }

    func body(content: Content) -> some View {
        content
            .background(
                glowBackground
                    .ignoresSafeArea()
            )
            .onAppear { startAnimation() }
            .onChange(of: isActive) { _, _ in startAnimation() }
    }

    private var glowBackground: some View {
        ZStack {
            RadialGradient(
                colors: colors,
                center: .center,
                startRadius: 20,
                endRadius: 400
            )
            .scaleEffect(scale)
            .offset(x: offsetX, y: offsetY)

            EllipticalGradient(
                colors: [
                    colors.last?.opacity(0.5) ?? .clear,
                    .clear
                ],
                center: .bottomTrailing
            )
            .scaleEffect(scale * 0.9)
            .offset(x: -offsetX * 0.7, y: -offsetY * 0.5)
        }
        .drawingGroup()
    }

    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
        ) {
            offsetX = motionRange
            offsetY = motionRange * 0.6
            scale = isActive ? 1.15 : 1.05
        }
    }
}

extension View {
    func keyboardGlow(keyboard: KeyboardObserver) -> some View {
        modifier(KeyboardGlowModifier(keyboard: keyboard))
    }
}
