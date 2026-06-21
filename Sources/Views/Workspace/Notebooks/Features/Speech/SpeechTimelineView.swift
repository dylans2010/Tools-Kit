import SwiftUI

struct SpeechTimelineView: View {
    let topics: [NotebookSpeechTopic]
    let currentProgress: TimeInterval
    let duration: TimeInterval
    var onSeek: (TimeInterval) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Topics")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topics) { topic in
                        Button {
                            onSeek(topic.startTime)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topic.title)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)

                                Text(formatTime(topic.startTime))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(width: 140, alignment: .leading)
                            .background(
                                isCurrentTopic(topic) ?
                                Color.accentColor.opacity(0.15) :
                                Color(.secondarySystemGroupedBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isCurrentTopic(topic) ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func isCurrentTopic(_ topic: NotebookSpeechTopic) -> Bool {
        currentProgress >= topic.startTime && currentProgress < topic.endTime
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
