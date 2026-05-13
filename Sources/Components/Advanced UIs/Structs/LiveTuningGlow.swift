import SwiftUI
import Aurora

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
