import SwiftUI

struct MiniPlayer: View {
    @StateObject private var player = MusicPlayerManager.shared
    @Binding var showNowPlaying: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at top edge
            progressBar

            HStack(spacing: 0) {
                // Tap anywhere except buttons → open NowPlayingView
                Button {
                    showNowPlaying = true
                } label: {
                    HStack(spacing: 10) {
                        artworkThumbnail

                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.currentSong?.title ?? "")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text(player.currentSong?.artist ?? "")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Controls
                HStack(spacing: 0) {
                    playerButton(systemName: "backward.fill") {
                        player.previous()
                    }

                    playerButton(systemName: player.isPlaying ? "pause.fill" : "play.fill") {
                        player.togglePlayPause()
                    }

                    playerButton(systemName: "forward.fill") {
                        player.next()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
        }
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 3)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            let progress = player.duration > 0 ? player.currentTime / player.duration : 0
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 2)
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, progress))), height: 2)
            }
        }
        .frame(height: 2)
        .clipShape(RoundedRectangle(cornerRadius: 1))
        .allowsHitTesting(false)
    }

    // MARK: - Artwork

    private var artworkThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(.systemGray5))
            if let data = player.currentSong?.artworkData,
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(2)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 40, height: 40)
        .cornerRadius(7)
        .clipped()
    }

    // MARK: - Player Button

    private func playerButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
