import SwiftUI
import MediaPlayer
import AVFoundation

struct NowPlayingView: View {
    @StateObject private var player = MusicPlayerManager.shared
    @StateObject private var engine = LyricsSyncEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGFloat = 0
    @State private var showQueue = false
    @State private var showLyrics = false
    @State private var showLRCImportSheet = false
    @State private var showLyricsSettings = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundView
                VStack(spacing: 0) {
                    headerRow
                        .padding(.horizontal, 24)
                        .padding(.top, max(14, geo.safeAreaInsets.top + 4))
                        .padding(.bottom, 8)

                    if showLyrics {
                        LyricsView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        artworkSection(availableHeight: geo.size.height)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))

                        bottomControls(screenHeight: geo.size.height)
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(geo.safeAreaInsets.bottom, 16))
                    }
                }
            }
        }
        .ignoresSafeArea()
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
        .offset(y: dragOffset)
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: showLyrics)
        .sheet(isPresented: $showQueue) { QueueView() }
        .sheet(isPresented: $showLyricsSettings) {
            if let song = player.currentSong {
                LyricsSettingsPanel(song: song, isVisible: $showLyricsSettings)
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let data = player.currentSong?.artworkData,
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
                    .drawingGroup()
                    .transition(.opacity)
            }
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            LinearGradient(
                colors: [Color.black.opacity(0.25), Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("NOW PLAYING")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(1.5)
                if let title = player.currentSong?.title {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }

            Spacer()

            Menu {
                if let song = player.currentSong {
                    Button {
                        player.addToQueue(song)
                    } label: {
                        Label("Add to Queue", systemImage: "text.badge.plus")
                    }
                }
                Button {
                    showLyrics.toggle()
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

    // MARK: - Artwork

    private func artworkSection(availableHeight: CGFloat) -> some View {
        let artworkPad: CGFloat = availableHeight < 700 ? 18 : 30
        let maxCardWidth: CGFloat = min(UIScreen.main.bounds.width - (artworkPad * 2), 420)
        let vPad: CGFloat = availableHeight < 700 ? 8 : 16
        return VStack(spacing: 0) {
            Spacer(minLength: vPad)
            artworkCard
                .frame(width: maxCardWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, artworkPad)
            Spacer(minLength: vPad)
        }
    }

    private var artworkCard: some View {
        Group {
            if let data = player.currentSong?.artworkData,
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(14)
                    .clipped()
                    .background(Color.black.opacity(0.2))
                    .shadow(color: .black.opacity(0.55), radius: 36, x: 0, y: 14)
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray4), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.35))
                    )
                    .shadow(color: .black.opacity(0.5), radius: 36, x: 0, y: 14)
            }
        }
        .id(player.currentSong?.id)
        .scaleEffect(player.isPlaying ? 1.0 : 0.82)
        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: player.isPlaying)
    }

    // MARK: - Bottom Controls Stack

    private func bottomControls(screenHeight: CGFloat) -> some View {
        let compact = screenHeight < 700
        let vGap: CGFloat = compact ? 10 : 18
        return VStack(spacing: 0) {
            songInfoRow
                .padding(.bottom, vGap)

            progressSection
                .padding(.bottom, vGap)

            mainControlsRow
                .padding(.bottom, compact ? 12 : 20)

            volumeRow
                .padding(.bottom, compact ? 10 : 18)

            secondaryControlsRow
                .padding(.bottom, compact ? 8 : 16)
        }
    }

    // MARK: - Song Info

    private var songInfoRow: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.currentSong?.title ?? "Not Playing")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(player.currentSong?.artist ?? " ")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }
            Spacer()
            Button {
                withAnimation { showLyrics.toggle() }
            } label: {
                ZStack {
                    Circle()
                        .fill(showLyrics ? Color.white.opacity(0.22) : Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: showLyrics ? "photo" : "quote.bubble.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(showLyrics ? .white : .white.opacity(0.75))
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(0, geo.size.width * CGFloat(safeProgress)), height: 4)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.3), radius: 3)
                        .offset(x: max(0, geo.size.width * CGFloat(safeProgress)) - 7)
                }
                .contentShape(Rectangle().inset(by: -12))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            let ratio = max(0, min(1, v.location.x / geo.size.width))
                            player.seek(to: Double(ratio) * player.duration)
                        }
                )
            }
            .frame(height: 14)

            HStack {
                Text(formatTime(player.currentTime))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Text("-" + formatTime(max(0, player.duration - player.currentTime)))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }

    private var safeProgress: Double {
        guard player.duration > 0 else { return 0 }
        return min(1, max(0, player.currentTime / player.duration))
    }

    // MARK: - Main Controls

    private var mainControlsRow: some View {
        HStack(spacing: 0) {
            // Previous
            Button { player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }

            // Play / Pause – large
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .contentShape(Rectangle())
            }

            // Next
            Button { player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Volume

    private var volumeRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
            SystemVolumeSlider()
                .frame(height: 32)
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
        }
    }

    // MARK: - Secondary Controls

    private var secondaryControlsRow: some View {
        HStack {
            // Shuffle
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 20))
                    .foregroundColor(player.shuffleEnabled ? .white : .white.opacity(0.38))
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

            // Queue
            Button { showQueue = true } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.72))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            // Repeat
            Button {
                let modes = RepeatMode.allCases
                let idx = ((modes.firstIndex(of: player.repeatMode) ?? 0) + 1) % modes.count
                player.setRepeatMode(modes[idx])
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: repeatIcon)
                        .font(.system(size: 20))
                        .foregroundColor(player.repeatMode != .off ? .white : .white.opacity(0.38))
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
    }

    // MARK: - Helpers

    private var repeatIcon: String {
        switch player.repeatMode {
        case .off: return "repeat"
        case .one: return "repeat"
        case .all: return "repeat"
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
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
