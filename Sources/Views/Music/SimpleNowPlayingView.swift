import SwiftUI
import MediaPlayer

struct SimpleNowPlayingView: View {
    @StateObject private var player = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var dragOffset: CGFloat = 0
    @State private var showLyrics = false
    @State private var showQueue = false
    @State private var showLyricsSettings = false

    private var artworkImage: UIImage? {
        player.currentSong?.artworkData.flatMap(UIImage.init)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                artworkBackground

                VStack(spacing: 0) {
                    topHandle(geo: geo)
                        .padding(.top, geo.safeAreaInsets.top + 4)

                    if showLyrics {
                        LyricsView()
                            .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.40)
                            .padding(.top, 8)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        artworkSection
                            .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.42)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }

                    Spacer(minLength: 16)
                    songInfoRow
                    Spacer(minLength: 14)
                    progressSection
                    Spacer(minLength: 14)
                    mainControls
                    Spacer(minLength: 10)
                    volumeRow
                    Spacer(minLength: 12)
                    bottomButtons
                    Spacer(minLength: max(geo.safeAreaInsets.bottom, 20))
                }
                .padding(.horizontal, 28)
                .offset(y: dragOffset)
            }
            .ignoresSafeArea()
        }
        .background(Color.black)
        .animation(.spring(response: 0.42, dampingFraction: 0.9), value: showLyrics)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { v in
                    if v.translation.height > 0 { dragOffset = v.translation.height * 0.6 }
                }
                .onEnded { v in
                    if v.translation.height > 80 { dismiss() }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { dragOffset = 0 }
                }
        )
        .sheet(isPresented: $showQueue) { QueueView() }
        .sheet(isPresented: $showLyricsSettings) {
            if let song = player.currentSong {
                LyricsSettingsPanel(song: song, isVisible: $showLyricsSettings)
            }
        }
    }

    // MARK: - Background

    private var artworkBackground: some View {
        ZStack {
            Color.black
            if let img = artworkImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .blur(radius: 55)
                    .opacity(0.7)
                    .overlay(Color.black.opacity(0.45))
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Handle

    private func topHandle(geo: GeometryProxy) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("NOW PLAYING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(2.5)
                Text(player.currentSong?.title ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }

            Spacer()

            moreMenu
                .frame(width: 44, height: 44)
        }
    }

    private var moreMenu: some View {
        Menu {
            Button {
                showQueue = true
            } label: {
                Label("Queue", systemImage: "list.bullet.below.rectangle")
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

            if let song = player.currentSong {
                Divider()
                Button {
                    player.addToQueue(song)
                } label: {
                    Label("Add to Queue", systemImage: "text.badge.plus")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.85))
                .contentShape(Rectangle())
        }
    }

    // MARK: - Artwork

    private var artworkSection: some View {
        VStack {
            Spacer()
            ZStack {
                if let img = artworkImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.55), radius: 28, x: 0, y: 14)
                        .scaleEffect(player.isPlaying ? 1.0 : 0.93)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75),
                                   value: player.isPlaying)
                } else {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(colors: [Color(.systemGray4), Color(.systemGray6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 72))
                                .foregroundColor(.white.opacity(0.35))
                        )
                        .shadow(color: .black.opacity(0.5), radius: 28, x: 0, y: 14)
                }
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    // MARK: - Song Info

    private var songInfoRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.currentSong?.title ?? "Not Playing")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(player.currentSong?.artist ?? "")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            Spacer()
            Button {
                withAnimation { showLyrics.toggle() }
            } label: {
                Image(systemName: showLyrics ? "photo" : "text.quote")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Progress Slider

    private var progressSection: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: min(max($0, 0), player.duration)) }
                ),
                in: 0...max(player.duration, 0.1)
            )
            .tint(.white)

            HStack {
                Text(formatTime(player.currentTime))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Text("-\(formatTime(max(0, player.duration - player.currentTime)))")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }

    // MARK: - Main Controls

    private var mainControls: some View {
        HStack {
            shuffleButton
            Spacer()
            prevButton
            Spacer(minLength: 16)
            playPauseButton
            Spacer(minLength: 16)
            nextButton
            Spacer()
            repeatButton
        }
    }

    private var shuffleButton: some View {
        Button { player.toggleShuffle() } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "shuffle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(player.shuffleEnabled ? .white : .white.opacity(0.45))
                if player.shuffleEnabled {
                    Circle().fill(Color.white).frame(width: 5, height: 5)
                        .offset(x: 2, y: -2)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
    }

    private var prevButton: some View {
        Button { player.previous() } label: {
            Image(systemName: "backward.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
    }

    private var playPauseButton: some View {
        Button { player.togglePlayPause() } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 76, height: 76)
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                    .offset(x: player.isPlaying ? 0 : 2)
            }
        }
    }

    private var nextButton: some View {
        Button { player.next() } label: {
            Image(systemName: "forward.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
    }

    private var repeatButton: some View {
        Button {
            let modes = RepeatMode.allCases
            let idx = ((modes.firstIndex(of: player.repeatMode) ?? 0) + 1) % modes.count
            player.setRepeatMode(modes[idx])
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "repeat")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(player.repeatMode != .off ? .white : .white.opacity(0.45))
                if player.repeatMode == .one {
                    Text("1")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 6, y: -6)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Volume

    private var volumeRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            SystemVolumeSliderView()
                .frame(height: 30)
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 14) {
            pillButton(icon: "text.quote", label: "Lyrics") {
                withAnimation { showLyrics.toggle() }
            }
            pillButton(icon: "list.bullet.below.rectangle", label: "Queue") {
                showQueue = true
            }
            if showLyrics {
                pillButton(icon: "slider.horizontal.3", label: "Sync") {
                    showLyricsSettings = true
                }
            }
            Spacer()
        }
    }

    private func pillButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - System Volume Slider

private struct SystemVolumeSliderView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let v = MPVolumeView()
        v.showsRouteButton = false
        return v
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        DispatchQueue.main.async {
            for sub in uiView.subviews {
                guard let slider = sub as? UISlider else { continue }
                slider.minimumTrackTintColor = UIColor.white
                slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.25)
                slider.thumbTintColor = UIColor.white
            }
        }
    }
}
