import Aurora
import SwiftUI

public struct HeroGlow: View {
    public var style: AuroraGlow.Style
    public var burster: AuroraGlow.Burster?

    public init(style: AuroraGlow.Style = .dramatic, burster: AuroraGlow.Burster? = nil) {
        self.style = style
        self.burster = burster
    }

    public var body: some View {
        let glow = AuroraGlow(style)
        if let burster = burster {
            glow.burster(burster)
                .ignoresSafeArea()
        } else {
            glow.ignoresSafeArea()
        }
    }
}
