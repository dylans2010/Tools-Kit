import Aurora
import SwiftUI

public struct LiveTuningGlow: View {
    public var style: AuroraGlow.Style
    public var cornerRadius: CGFloat
    public var borderWidth: CGFloat
    public var glowSize: CGFloat
    public var speed: Double
    public var burster: AuroraGlow.Burster?

    public init(
        style: AuroraGlow.Style = .standard,
        cornerRadius: CGFloat = 55,
        borderWidth: CGFloat = 6,
        glowSize: CGFloat = 28,
        speed: Double = 0.12,
        burster: AuroraGlow.Burster? = nil
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.glowSize = glowSize
        self.speed = speed
        self.burster = burster
    }

    public var body: some View {
        let glow = AuroraGlow(style)
            .cornerRadius(cornerRadius)
            .borderWidth(borderWidth)
            .glowSize(glowSize)
            .speed(speed)

        if let burster = burster {
            glow.burster(burster)
                .ignoresSafeArea()
        } else {
            glow.ignoresSafeArea()
        }
    }
}
