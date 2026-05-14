import SwiftUI
import Aurora

public struct AIAnimationCoreModifier: ViewModifier {
    let isLoading: Bool

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isLoading {
                AuroraGlow(.dramatic)
                    .washSweepDuration(1.00)
                    .washPulseWidth(1.00)
                    .washPeak(0.80)
                    .direction(.bottomToTop)
                    .introStyle(.borderFill)
                    .introDuration(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

extension View {
    public func aiAnimationLoading(_ isLoading: Bool) -> some View {
        self.modifier(AIAnimationCoreModifier(isLoading: isLoading))
    }
}
