import SwiftUI

struct LiveCaptionsView: View {
    let isEnabled: Bool
    let captions: [MeetingCaptionLine]
    let onToggleVisibility: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Live Captions", isOn: Binding(get: { isEnabled }, set: onToggleVisibility))
            if isEnabled {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(captions) { line in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(line.speaker) · \(line.timestamp.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(line.text)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
