import SwiftUI
import Aurora


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
            .washPeak(Float(intensity * 0.15))

        if ignoresSafeArea {
            glow.ignoresSafeArea()
        } else {
            glow
        }
    }
}

// MARK: - Specialized Glow Structs

public struct LiveTuningGlow: View {
    public var style: AuroraGlow.Style = .standard
    public var cornerRadius: CGFloat = 55
    public var borderWidth: CGFloat = 6
    public var glowSize: CGFloat = 28
    public var speed: Double = 0.12

    public init(style: AuroraGlow.Style = .standard, cornerRadius: CGFloat = 55, borderWidth: CGFloat = 6, glowSize: CGFloat = 28, speed: Double = 0.12) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.glowSize = glowSize
        self.speed = speed
    }

    public var body: some View {
        AuroraGlow(style)
            .cornerRadius(cornerRadius)
            .borderWidth(borderWidth)
            .glowSize(glowSize)
            .speed(speed)
            .ignoresSafeArea()
    }
}

public struct WashGlow: View {
    public var style: AuroraGlow.Style = .dramatic
    public var cornerRadius: CGFloat = 55
    public var borderWidth: CGFloat = 6
    public var glowSize: CGFloat = 28
    public var speed: Double = 0.12
    public var pulseWidth: Float = 0.8
    public var peak: Float = 0.1

    public init(style: AuroraGlow.Style = .dramatic, cornerRadius: CGFloat = 55, borderWidth: CGFloat = 6, glowSize: CGFloat = 28, speed: Double = 0.12, pulseWidth: Float = 0.8, peak: Float = 0.1) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.glowSize = glowSize
        self.speed = speed
        self.pulseWidth = pulseWidth
        self.peak = peak
    }

    public var body: some View {
        AuroraGlow(style)
            .cornerRadius(cornerRadius)
            .borderWidth(borderWidth)
            .glowSize(glowSize)
            .speed(speed)
            .washPulseWidth(pulseWidth)
            .washPeak(peak)
            .ignoresSafeArea()
    }
}

public struct CustomGlow: View {
    public var anchorAmp: Float = 0.38
    public var anchorSpd: Float = 2.2
    public var flameAmp: Float = 2.0
    public var decayRate: Float = 1.6

    public init(anchorAmp: Float = 0.38, anchorSpd: Float = 2.2, flameAmp: Float = 2.0, decayRate: Float = 1.6) {
        self.anchorAmp = anchorAmp
        self.anchorSpd = anchorSpd
        self.flameAmp = flameAmp
        self.decayRate = decayRate
    }

    public var body: some View {
        AuroraGlow(profile: AuroraGlow.Profile(
            anchorAmpBoost: anchorAmp,
            anchorSpeedBoost: anchorSpd,
            flameAmpBoost: flameAmp,
            decayRate: decayRate
        ))
        .ignoresSafeArea()
    }
}

public struct MoodGlow: View {
    public var mood: AuroraGlow.Mood = .listening
    public var style: AuroraGlow.Style = .standard
    public var cornerRadius: CGFloat = 55
    public var borderWidth: CGFloat = 6
    public var glowSize: CGFloat = 28
    public var speed: Double = 0.12

    public init(mood: AuroraGlow.Mood = .listening, style: AuroraGlow.Style = .standard, cornerRadius: CGFloat = 55, borderWidth: CGFloat = 6, glowSize: CGFloat = 28, speed: Double = 0.12) {
        self.mood = mood
        self.style = style
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.glowSize = glowSize
        self.speed = speed
    }

    public var body: some View {
        AuroraGlow(style)
            .mood(mood)
            .cornerRadius(cornerRadius)
            .borderWidth(borderWidth)
            .glowSize(glowSize)
            .speed(speed)
            .ignoresSafeArea()
    }
}

// MARK: - Loading Modifier

public struct GlowWhileLoadingModifier<Glow: View>: ViewModifier {
    let isLoading: Bool
    let glow: Glow

    public func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                glow
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isLoading)
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

    /// Shows a full-screen glow animation while a loading condition is met.
    public func glowWhileLoading<Glow: View>(_ isLoading: Bool, @ViewBuilder glow: () -> Glow) -> some View {
        self.modifier(GlowWhileLoadingModifier(isLoading: isLoading, glow: glow()))
    }
}
