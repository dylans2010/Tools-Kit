import SwiftUI
import MediaPlayer

struct NowPlayingView: View {
    @StateObject private var player = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGFloat = 0
    @State private var showQueue = false
    @State private var showLyrics = false
    @State private var showLyricsSettings = false

    private var artworkImage: UIImage? {
        guard let data = player.currentSong?.artworkData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ArtworkBackground(image: artworkImage)
                VStack(spacing: 18) {
                    header(geo: geo)

                    if showLyrics {
                        LyricsView()
                            .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.38)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        artworkHero
                            .frame(maxHeight: geo.size.height * 0.42)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }

                    songInfo
                    progressSlider
                    playbackControls
                    utilityRow
                }
                .padding(.horizontal, 20)
                .padding(.top, geo.safeAreaInsets.top + 6)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 18))
                .offset(y: dragOffset)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { v in
                    if v.translation.height > 0 { dragOffset = v.translation.height }
                }
                .onEnded { v in
                    if v.translation.height > 80 { dismiss() }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { dragOffset = 0 }
                }
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: showLyrics)
        .sheet(isPresented: $showQueue) { QueueView() }
        .sheet(isPresented: $showLyricsSettings) {
            if let song = player.currentSong {
                LyricsSettingsPanel(song: song, isVisible: $showLyricsSettings)
            }
        }
    }

    // MARK: - Header

    private func header(geo: GeometryProxy) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            VStack(spacing: 4) {
                Text("NOW PLAYING")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(2)
                Text(player.currentSong?.title ?? "Not Playing")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    showQueue = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                Menu {
                    if let song = player.currentSong {
                        Button {
                            player.addToQueue(song)
                        } label: {
                            Label("Add to Queue", systemImage: "text.badge.plus")
                        }
                    }
                    Button {
                        withAnimation { showLyrics.toggle() }
                    } label: {
                        Label(showLyrics ? "Show Artwork" : "Show Lyrics",
                              systemImage: showLyrics ? "photo" : "text.quote")
                    }
                    if showLyrics {
                        Button {
                            showLyricsSettings = true
                        } label: {
                            Label("Lyrics Settings", systemImage: "slider.horizontal.3")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
    }

    // MARK: - Artwork

    private var artworkHero: some View {
        ZStack {
            if let image = artworkImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 12)
                    .transition(.opacity)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray4), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 300, height: 300)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.4))
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Song Info

    private var songInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(player.currentSong?.title ?? "Not Playing")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(player.currentSong?.artist ?? "")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Progress

    private var progressSlider: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { newValue in
                        let clamped = min(max(newValue, 0), player.duration)
                        player.seek(to: clamped)
                    }
                ),
                in: 0...max(player.duration, 0.1)
            )
            .tint(.white)

            HStack {
                Text(formatTime(player.currentTime))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("-" + formatTime(max(0, player.duration - player.currentTime)))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        VStack(spacing: 14) {
            HStack {
                Button { player.toggleShuffle() } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(player.shuffleEnabled ? .white : .white.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .overlay(alignment: .topTrailing) {
                            if player.shuffleEnabled {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 5)
                                    .offset(x: -2, y: 2)
                            }
                        }
                }

                Spacer()

                Button { player.previous() } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }

                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 72, height: 72)
                        .contentShape(Rectangle())
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 88, height: 88)
                        )
                }

                Button { player.next() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }

                Spacer()

                Button {
                    let modes = RepeatMode.allCases
                    let idx = ((modes.firstIndex(of: player.repeatMode) ?? 0) + 1) % modes.count
                    player.setRepeatMode(modes[idx])
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "repeat")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(player.repeatMode != .off ? .white : .white.opacity(0.5))
                        if player.repeatMode == .one {
                            Text("1")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: 6, y: -6)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                SystemVolumeSlider()
                    .frame(height: 32)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Utility Row

    private var utilityRow: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation { showLyrics.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showLyrics ? "photo" : "text.quote")
                    Text(showLyrics ? "Artwork" : "Lyrics")
                }
                .font(.system(size: 14, weight: .semibold))
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.12))
                .cornerRadius(12)
            }

            if showLyrics {
                Button {
                    showLyricsSettings = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Sync")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Background

private struct ArtworkBackground: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .blur(radius: 50)
                    .overlay(Color.black.opacity(0.55))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }
}

// MARK: - System Volume Slider (MPVolumeView wrapper)

private struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        view.showsRouteButton = false
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        DispatchQueue.main.async {
            for sub in uiView.subviews {
                guard let slider = sub as? UISlider else { continue }
                slider.minimumTrackTintColor = .white
                slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.28)
                slider.thumbTintColor = .white
            }
        }
    }
}
