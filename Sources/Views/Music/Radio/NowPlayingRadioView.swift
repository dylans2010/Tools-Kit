import SwiftUI

struct NowPlayingRadioView: View {
    @StateObject private var player = RadioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0
    @State private var loadingRotation: Double = 0

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 0) {
                handle
                Spacer()
                faviconHero
                Spacer(minLength: 20)
                stationInfo
                Spacer(minLength: 30)
                controls
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .offset(y: dragOffset)
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
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            if let url = player.currentStation?.faviconURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .blur(radius: 60)
                            .overlay(Color.black.opacity(0.65))
                    } else {
                        Color.black
                    }
                }
            } else {
                Color.black
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Handle

    private var handle: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Radio")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
            }
            Spacer()
            // Favorite button
            Button {
                if let station = player.currentStation {
                    player.toggleFavorite(station)
                }
            } label: {
                Image(systemName: (player.currentStation.map { player.isFavorite($0) } ?? false)
                      ? "heart.fill" : "heart")
                    .font(.system(size: 18))
                    .foregroundColor(
                        (player.currentStation.map { player.isFavorite($0) } ?? false)
                        ? .red : .white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Favicon Hero

    private var faviconHero: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 220, height: 220)

            if let url = player.currentStation?.faviconURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.4), radius: 20)
                    case .failure:
                        radioIcon
                    case .empty:
                        ProgressView().tint(.white)
                    @unknown default:
                        radioIcon
                    }
                }
            } else {
                radioIcon
            }

            // Loading ring
            if case .loading = player.playbackState {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.25)
                            .stroke(Color.white, lineWidth: 3)
                            .rotationEffect(.degrees(-90))
                    )
                    .rotationEffect(.degrees(loadingRotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            loadingRotation = 360
                        }
                    }
                    .onDisappear { loadingRotation = 0 }
            }
        }
        .frame(width: 220, height: 220)
    }

    private var radioIcon: some View {
        Image(systemName: "antenna.radiowaves.left.and.right")
            .font(.system(size: 72))
            .foregroundColor(.white.opacity(0.5))
    }

    // MARK: - Station Info

    private var stationInfo: some View {
        VStack(spacing: 8) {
            Text(player.currentStation?.name ?? "No Station")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: 12) {
                if let country = player.currentStation?.country, !country.isEmpty {
                    label(text: country, icon: "globe")
                }
                if let bitrate = player.currentStation?.bitrateLabel, !bitrate.isEmpty {
                    label(text: bitrate, icon: "waveform")
                }
                if let codec = player.currentStation?.codec, !codec.isEmpty {
                    label(text: codec.uppercased(), icon: nil)
                }
            }

            stateView
        }
    }

    private func label(text: String, icon: String?) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
            }
            Text(text)
                .font(.system(size: 13))
        }
        .foregroundColor(.white.opacity(0.7))
    }

    @ViewBuilder
    private var stateView: some View {
        switch player.playbackState {
        case .loading:
            HStack(spacing: 6) {
                ProgressView().tint(.white).scaleEffect(0.8)
                Text("Connecting…")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 4)
        case .error(let msg):
            Text(msg)
                .font(.subheadline)
                .foregroundColor(.red.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        default:
            EmptyView()
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 48) {
            Button {
                player.stop()
                dismiss()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 52, height: 52)
                    .contentShape(Circle())
            }

            Button {
                player.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.3), radius: 12)

                    if case .loading = player.playbackState {
                        ProgressView().tint(.black).scaleEffect(1.1)
                    } else {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.black)
                            .offset(x: player.isPlaying ? 0 : 2)
                    }
                }
            }

            Button {
                if let station = player.currentStation {
                    player.toggleFavorite(station)
                }
            } label: {
                Image(systemName:
                        (player.currentStation.map { player.isFavorite($0) } ?? false)
                      ? "heart.fill" : "heart")
                    .font(.system(size: 24))
                    .foregroundColor(
                        (player.currentStation.map { player.isFavorite($0) } ?? false)
                        ? .red : .white.opacity(0.8))
                    .frame(width: 52, height: 52)
                    .contentShape(Circle())
            }
        }
    }
}
