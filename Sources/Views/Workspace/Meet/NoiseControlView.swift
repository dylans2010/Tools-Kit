import SwiftUI

struct NoiseControlView: View {
    let isEnabled: Bool
    let processingState: String
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Noise Cancellation", isOn: Binding(get: { isEnabled }, set: onToggle))
            Label(processingState, systemImage: isEnabled ? "waveform.and.mic" : "mic")
                .font(.caption)
                .foregroundStyle(isEnabled ? .green : .secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
