import SwiftUI

/// A view modifier that renders a dynamic, fluid gradient glow background behind content.
/// Intensity and motion increase when the keyboard is visible.
/// Works in concert with ``KeyboardBackdropManager`` which places a separate UIWindow
/// behind the system keyboard to show the gradient glow beneath the keys.
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
            Color(.systemIndigo).opacity(0.42),
            Color(.systemPurple).opacity(0.34),
            Color(.systemCyan).opacity(0.28),
            Color(.systemBlue).opacity(0.20)
        ]
    }

    private var colors: [Color] { isActive ? activeColors : idleColors }

    private var motionRange: CGFloat { isActive ? 35 : 10 }
    private var animationDuration: Double { isActive ? 2.2 : 4.0 }

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

            // Extra glow pulse when keyboard is active
            if isActive {
                RadialGradient(
                    colors: [
                        Color(.systemCyan).opacity(0.18),
                        Color(.systemIndigo).opacity(0.10),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 10,
                    endRadius: 300
                )
                .scaleEffect(scale * 1.1)
                .offset(y: offsetY * 0.3)
            }
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
            scale = isActive ? 1.18 : 1.05
        }
    }
}

extension View {
    func keyboardGlow(keyboard: KeyboardObserver) -> some View {
        modifier(KeyboardGlowModifier(keyboard: keyboard))
    }
}
