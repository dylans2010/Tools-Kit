import SwiftUI

struct NoiseControlView: View {
    let isEnabled: Bool
    let processingState: String
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Noise Cancellation", systemImage: "waveform.and.mic")
                .font(.subheadline.weight(.semibold))
            Toggle("Enable Filtering", isOn: Binding(get: { isEnabled }, set: onToggle))
            Label(processingState, systemImage: isEnabled ? "checkmark.circle.fill" : "mic.slash")
                .font(.caption)
                .foregroundStyle(isEnabled ? Color.green : Color.secondary)
        }
    }
}
