import SwiftUI

struct AnimationTimelineView: View {
    @ObservedObject var runtime = AnimationRuntime.shared
    @Binding var keyframes: [AnimationRuntime.Keyframe]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { runtime.isPlaying ? runtime.pause() : runtime.play() }) {
                    Image(systemName: runtime.isPlaying ? "pause.fill" : "play.fill")
                }
                Slider(value: $runtime.currentTime, in: 0...30)
                Text(String(format: "%.2fs", runtime.currentTime))
                    .font(.caption2.monospacedDigit())
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))

            ScrollView(.horizontal) {
                ZStack(alignment: .topLeading) {
                    // Timeline grid
                    TimelineGrid()

                    // Keyframes
                    ForEach(keyframes) { kf in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(x: CGFloat(kf.time * 50), y: 20)
                    }
                }
                .frame(width: 1500, height: 100)
            }
        }
        .background(.ultraThinMaterial)
    }
}

struct TimelineGrid: View {
    var body: some View {
        Canvas { context, size in
            for i in 0..<30 {
                let x = CGFloat(i) * 50
                context.stroke(Path(CGRect(x: x, y: 0, width: 1, height: size.height)), with: .color(.gray.opacity(0.2)))
            }
        }
    }
}
