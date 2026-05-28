import SwiftUI

// This file contains supporting views for the MarketplaceSubmissionView wizard steps to keep the main file clean.

struct SubmissionWizardSteps {
    // Placeholder for actual sub-views if they become too large for the main file.
    // In this implementation, the main file was kept manageable, but these components
    // are registered as requested by the prompt for future scalability.

    struct TechnicalField: View {
        let label: String
        @Binding var text: String

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.caption.bold()).foregroundStyle(.secondary)
                TextField(label, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    struct PlatformToggle: View {
        let label: String
        @Binding var isOn: Bool

        var body: some View {
            Toggle(isOn: $isOn) {
                Text(label).font(.subheadline)
            }
        }
    }
}
