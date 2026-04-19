import SwiftUI

#if canImport(Daily)
import Daily
#endif

struct VideoTileView: View {
    let participant: MeetingParticipant
    let track: MeetingVideoTrack?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            videoSurface
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(participant.displayName)
                        .font(.caption.weight(.semibold))
                    if participant.isSpeaking {
                        Image(systemName: "waveform")
                            .foregroundStyle(.green)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                        .foregroundStyle(participant.isMuted ? .red : .green)
                    Text(participant.role.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private var videoSurface: some View {
        #if canImport(Daily)
        if let track {
            MeetingDailyVideoView(track: track)
        }
        #else
        EmptyView()
        #endif
    }
}

#if canImport(Daily)
private struct MeetingDailyVideoView: UIViewRepresentable {
    let track: VideoTrack

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        view.videoScaleMode = .fit
        return view
    }

    func updateUIView(_ uiView: VideoView, context: Context) {
        uiView.track = track
    }
}
#endif
