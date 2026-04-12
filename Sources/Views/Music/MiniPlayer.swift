import SwiftUI

struct MiniPlayer: View {
    @StateObject private var player = MusicPlayerManager.shared
    @Binding var showNowPlaying: Bool

    var body: some View {
        Button {
            showNowPlaying = true
        } label: {
            HStack(spacing: 12) {
                artworkView
                    .frame(width: 38, height: 38)
                    .cornerRadius(6)
                    .clipped()

                VStack(alignment: .leading, spacing: 1) {
                    Text(player.currentSong?.title ?? "")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(player.currentSong?.artist ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .frame(width: 36, height: 36)

                Button {
                    player.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .overlay(alignment: .bottom) {
            let progress = player.duration > 0 ? player.currentTime / player.duration : 0
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(width: geo.size.width * CGFloat(progress), height: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var artworkView: some View {
        if let data = player.currentSong?.artworkData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .overlay(Image(systemName: "music.note").foregroundColor(.secondary))
        }
    }
}
