import SwiftUI
import Aurora

/// GlowingUIView is a reusable wrapper that applies a high-performance,
/// Metal-backed Aurora ambient glow to its content.
public struct GlowingUIView<Content: View>: View {
    private let content: Content
    private let style: AuroraGlow.Style
    private let palette: AuroraGlow.Palette
    private let speed: Double
    private let glowSize: Double
    private let intensity: Double
    private let ignoresSafeArea: Bool

    public init(
        style: AuroraGlow.Style = .standard,
        palette: AuroraGlow.Palette = .appleIntelligence,
        speed: Double = 0.12,
        glowSize: Double = 30,
        intensity: Double = 1.0,
        ignoresSafeArea: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.palette = palette
        self.speed = speed
        self.glowSize = glowSize
        self.intensity = intensity
        self.ignoresSafeArea = ignoresSafeArea
    }

    public var body: some View {
        ZStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay {
            glowView
        }
    }

    @ViewBuilder
    private var glowView: some View {
        let glow = AuroraGlow(style)
            .palette(palette)
            .speed(speed)
            .glowSize(glowSize)
            .washPeak(intensity * 0.15)

        if ignoresSafeArea {
            glow.ignoresSafeArea()
        } else {
            glow
        }
    }
}

extension View {
    /// Applies a full-screen Aurora ambient glow to the view.
    public func auroraGlow(
        style: AuroraGlow.Style = .standard,
        palette: AuroraGlow.Palette = .appleIntelligence,
        speed: Double = 0.12,
        glowSize: Double = 30,
        intensity: Double = 1.0
    ) -> some View {
        GlowingUIView(
            style: style,
            palette: palette,
            speed: speed,
            glowSize: glowSize,
            intensity: intensity,
            content: { self }
        )
    }
}
