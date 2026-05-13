import Aurora
import SwiftUI

public struct WashGlow: View {
    public var style: AuroraGlow.Style
    public var sweepDuration: Float
    public var pulseWidth: Float
    public var peak: Float
    public var introDuration: Float
    public var direction: AuroraGlow.Direction
    public var introStyle: AuroraGlow.IntroStyle

    public init(
        style: AuroraGlow.Style = .dramatic,
        sweepDuration: Float = 0.12,
        pulseWidth: Float = 0.80,
        peak: Float = 0.10,
        introDuration: Float = 0.5,
        direction: AuroraGlow.Direction = .topToBottom,
        introStyle: AuroraGlow.IntroStyle = .borderFill
    ) {
        self.style = style
        self.sweepDuration = sweepDuration
        self.pulseWidth = pulseWidth
        self.peak = peak
        self.introDuration = introDuration
        self.direction = direction
        self.introStyle = introStyle
    }

    public var body: some View {
        AuroraGlow(style)
            .washSweepDuration(sweepDuration)
            .washPulseWidth(pulseWidth)
            .washPeak(peak)
            .direction(direction)
            .introStyle(introStyle)
            .introDuration(introDuration)
            .ignoresSafeArea()
    }
}
