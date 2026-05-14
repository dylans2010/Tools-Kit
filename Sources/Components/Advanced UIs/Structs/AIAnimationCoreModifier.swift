import SwiftUI
import Aurora
import UIKit

public struct AIAnimationCoreModifier: ViewModifier {
    let isLoading: Bool
    @State private var alternateDirection = false

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isLoading {
                AuroraGlow(.dramatic)
                    .washSweepDuration(1.00)
                    .washPulseWidth(1.00)
                    .washPeak(0.80)
                    .direction(alternateDirection ? .topToBottom : .bottomToTop)
                    .introStyle(.borderFill)
                    .introDuration(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(100)
                    .onAppear {
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: true)) {
                            alternateDirection.toggle()
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onChange(of: isLoading) { _, newValue in
            guard newValue else { return }
            dismissKeyboardAggressively()
        }
    }

    private func dismissKeyboardAggressively() {
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .forEach { window in
                    window.endEditing(true)
                    window.rootViewController?.view.endEditing(true)
                    window.subviews.forEach { $0.endEditing(true) }
                }
        }
    }
}

extension View {
    public func aiAnimationLoading(_ isLoading: Bool) -> some View {
        self.modifier(AIAnimationCoreModifier(isLoading: isLoading))
    }
}
