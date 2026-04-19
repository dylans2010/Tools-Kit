import SwiftUI

struct PerformanceWarningView: View {
    let warnings: [MeetingCPUWarning]
    let onDismiss: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(warnings.suffix(2)) { warning in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(warning.message)
                            .font(.caption.weight(.semibold))
                        Text(warning.suggestedAction)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(role: .cancel) {
                        onDismiss(warning.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
