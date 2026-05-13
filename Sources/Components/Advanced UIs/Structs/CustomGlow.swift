import Aurora
import SwiftUI

public struct CustomGlow: View {
    public var anchorAmpBoost: Float
    public var anchorSpeedBoost: Float
    public var flameAmpBoost: Float
    public var brightnessPop: Float
    public var decayRate: Float
    public var flameBaseline: Float
    public var burster: AuroraGlow.Burster?

    public init(
        anchorAmpBoost: Float = 0.38,
        anchorSpeedBoost: Float = 2.2,
        flameAmpBoost: Float = 2.0,
        brightnessPop: Float = 0.32,
        decayRate: Float = 1.6,
        flameBaseline: Float = 0.45,
        burster: AuroraGlow.Burster? = nil
    ) {
        self.anchorAmpBoost = anchorAmpBoost
        self.anchorSpeedBoost = anchorSpeedBoost
        self.flameAmpBoost = flameAmpBoost
        self.brightnessPop = brightnessPop
        self.decayRate = decayRate
        self.flameBaseline = flameBaseline
        self.burster = burster
    }

    public var body: some View {
        let profile = AuroraGlow.Profile(
            anchorAmpBoost: anchorAmpBoost,
            anchorSpeedBoost: anchorSpeedBoost,
            flameAmpBoost: flameAmpBoost,
            brightnessPop: brightnessPop,
            decayRate: decayRate,
            flameBaseline: flameBaseline
        )
        let glow = AuroraGlow(profile: profile)

        if let burster = burster {
            glow.burster(burster)
                .ignoresSafeArea()
        } else {
            glow.ignoresSafeArea()
        }
    }
}
