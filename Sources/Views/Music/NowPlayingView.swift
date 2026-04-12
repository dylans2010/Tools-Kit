import SwiftUI

struct NowPlayingView: View {
    @StateObject private var player = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showQueue = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            backgroundView
            VStack(spacing: 0) {
                dragHandle
                    .padding(.top, 8)
                Spacer()
                artworkView
                    .padding(.horizontal, 40)
                Spacer()
                songInfo
                    .padding(.horizontal, 30)
                    .padding(.bottom, 16)
                progressSection
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                controls
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                secondaryControls
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { v in if v.translation.height > 0 { dragOffset = v.translation.height } }
                .onEnded { v in
                    if v.translation.height > 100 { dismiss() }
                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                }
        )
        .offset(y: dragOffset)
        .sheet(isPresented: $showQueue) { QueueView() }
    }

    private var backgroundView: some View {
        ZStack {
            if let data = player.currentSong?.artworkData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 60)
                    .scaleEffect(1.3)
                    .ignoresSafeArea()
                    .opacity(0.5)
            }
            Color(.systemBackground).opacity(0.65).ignoresSafeArea()
        }
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(.systemGray3))
            .frame(width: 40, height: 5)
    }

    @ViewBuilder
    private var artworkView: some View {
        if let data = player.currentSong?.artworkData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .cornerRadius(16)
                .shadow(radius: 20)
                .scaleEffect(player.isPlaying ? 1.0 : 0.88)
                .animation(.spring(response: 0.4), value: player.isPlaying)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                )
                .scaleEffect(player.isPlaying ? 1.0 : 0.88)
                .animation(.spring(response: 0.4), value: player.isPlaying)
        }
    }

    private var songInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.currentSong?.title ?? "Not Playing")
                    .font(.title3.bold())
                    .lineLimit(1)
                Text(player.currentSong?.artist ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(value: Binding(
                get: { player.duration > 0 ? player.currentTime / player.duration : 0 },
                set: { player.seek(to: $0 * player.duration) }
            ))
            HStack {
                Text(formatTime(player.currentTime))
                Spacer()
                Text(formatTime(player.duration))
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 0) {
            Spacer()
            Button { player.previous() } label: {
                Image(systemName: "backward.fill").font(.system(size: 28))
            }
            Spacer()
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
            }
            Spacer()
            Button { player.next() } label: {
                Image(systemName: "forward.fill").font(.system(size: 28))
            }
            Spacer()
        }
        .foregroundColor(.primary)
    }

    private var secondaryControls: some View {
        HStack {
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .foregroundColor(player.shuffleEnabled ? .accentColor : .secondary)
            }
            Spacer()
            Button { showQueue = true } label: {
                Image(systemName: "list.bullet").foregroundColor(.secondary)
            }
            Spacer()
            Button {
                let modes = RepeatMode.allCases
                let idx = ((modes.firstIndex(of: player.repeatMode) ?? 0) + 1) % modes.count
                player.setRepeatMode(modes[idx])
            } label: {
                Image(systemName: repeatIcon)
                    .foregroundColor(player.repeatMode != .off ? .accentColor : .secondary)
            }
        }
        .font(.title3)
    }

    private var repeatIcon: String {
        switch player.repeatMode {
        case .off: return "repeat"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite else { return "0:00" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}
