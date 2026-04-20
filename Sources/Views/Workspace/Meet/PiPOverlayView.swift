import SwiftUI

struct PiPOverlayView: View {
    let isEnabled: Bool
    let isActive: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Toggle("Picture in Picture", isOn: Binding(get: { isEnabled }, set: onToggle))
            if isActive {
                Label("Active", systemImage: "pip.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}
