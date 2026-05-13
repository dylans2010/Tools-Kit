import SwiftUI
import Aurora

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
