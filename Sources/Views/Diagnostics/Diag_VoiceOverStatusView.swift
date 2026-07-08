import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct Diag_VoiceOverStatusView: View {
    @State private var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @State private var isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
    @State private var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @State private var isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
    @State private var isGrayscaleEnabled = UIAccessibility.isGrayscaleEnabled
    @State private var isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled

    var body: some View {
        Form {
            Section("VoiceOver") {
                VStack(spacing: 12) {
                    Image(systemName: isVoiceOverRunning ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(isVoiceOverRunning ? .green : .secondary)

                    Text(isVoiceOverRunning ? "VoiceOver Active" : "VoiceOver Inactive")
                        .font(.title2.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Accessibility Settings") {
                AccessibilityRow(name: "VoiceOver", isEnabled: isVoiceOverRunning)
                AccessibilityRow(name: "Switch Control", isEnabled: isSwitchControlRunning)
                AccessibilityRow(name: "Reduce Motion", isEnabled: isReduceMotionEnabled)
                AccessibilityRow(name: "Bold Text", isEnabled: isBoldTextEnabled)
                AccessibilityRow(name: "Grayscale", isEnabled: isGrayscaleEnabled)
                AccessibilityRow(name: "Reduce Transparency", isEnabled: isReduceTransparencyEnabled)
            }

            Section {
                Button("Refresh") {
                    refreshStatus()
                }
            }
        }
        .navigationTitle("VoiceOver Status")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func refreshStatus() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        isGrayscaleEnabled = UIAccessibility.isGrayscaleEnabled
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    }
}

private struct AccessibilityRow: View {
    let name: String
    let isEnabled: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            Spacer()
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isEnabled ? .green : .secondary)
            Text(isEnabled ? "On" : "Off")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
