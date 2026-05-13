import SwiftUI
import Aurora

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
