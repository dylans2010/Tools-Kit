import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct NeonGlowModifier: ViewModifier {
    let color: Color
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.6 + 0.4 * Darwin.sin(phase)), lineWidth: 2)
            )
            .shadow(color: color.opacity(0.4 + 0.3 * Darwin.sin(phase)), radius: 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    phase = .pi
                }
            }
    }
}

struct PulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.08 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var shimmerOffset: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: shimmerOffset * geo.size.width)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.4
                }
            }
    }
}

struct GamingCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [GamingDesignTokens.cardSurface, GamingDesignTokens.cardSurface.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            )
    }
}

struct HapticOnTapModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            }
    }
}

extension View {
    func neonGlow(color: Color = GamingDesignTokens.accentNeon) -> some View {
        modifier(NeonGlowModifier(color: color))
    }

    func pulseAnimation() -> some View {
        modifier(PulseAnimationModifier())
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func gamingCard() -> some View {
        modifier(GamingCardModifier())
    }

    func hapticOnTap(action: @escaping () -> Void) -> some View {
        modifier(HapticOnTapModifier(action: action))
    }
}
