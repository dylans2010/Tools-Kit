import SwiftUI

// MARK: - Music Recommendation Engine (CoreML-compatible heuristics)

final class MusicRecommendationEngine {
    static func suggestions(from songs: [Song], limit: Int = 20) -> [Song] {
        guard !songs.isEmpty else { return [] }

        // Score each song using weighted signals (play count, recency, diversity)
        let maxPlays = songs.map(\.playCount).max() ?? 1
        let now = Date()

        let scored = songs.map { song -> (Song, Double) in
            // Normalize play count to [0,1]
            let playScore = maxPlays > 0 ? Double(song.playCount) / Double(maxPlays) : 0

            // Recency score – songs added within last 30 days get a boost
            let daysSinceAdded = now.timeIntervalSince(song.dateAdded) / 86_400
            let recencyScore = max(0, 1.0 - daysSinceAdded / 30.0)

            // Combined score with weights
            let score = playScore * 0.65 + recencyScore * 0.35
            return (song, score)
        }

        // Sort by descending score, then shuffle top half slightly to add variety
        let sorted = scored.sorted { $0.1 > $1.1 }.map(\.0)
        let topHalfCount = min(limit * 2, sorted.count)
        let topHalf = Array(sorted.prefix(topHalfCount)).shuffled()
        return Array(topHalf.prefix(limit))
    }

    static func recentlyAdded(from songs: [Song], limit: Int = 10) -> [Song] {
        Array(songs.sorted { $0.dateAdded > $1.dateAdded }.prefix(limit))
    }

    static func topPlayed(from songs: [Song], limit: Int = 10) -> [Song] {
        Array(songs.filter { $0.playCount > 0 }.sorted { $0.playCount > $1.playCount }.prefix(limit))
    }
}

// MARK: - MusicHomeView

struct MusicHomeView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var showNowPlaying = false
    @State private var suggestions: [Song] = []
    @State private var recentlyAdded: [Song] = []
    @State private var topPlayed: [Song] = []

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        if library.songs.isEmpty {
                            emptyLibraryPrompt
                                .padding(.top, 60)
                        } else {
                            if !suggestions.isEmpty {
                                SongSectionCarousel(
                                    title: "Suggested For You",
                                    subtitle: "Based on your listening",
                                    systemImage: "sparkles",
                                    songs: suggestions,
                                    onTap: playSong
                                )
                            }

                            if !recentlyAdded.isEmpty {
                                SongSectionCarousel(
                                    title: "Recently Added",
                                    subtitle: nil,
                                    systemImage: "clock",
                                    songs: recentlyAdded,
                                    onTap: playSong
                                )
                            }

                            if !topPlayed.isEmpty {
                                SongSectionCarousel(
                                    title: "Most Played",
                                    subtitle: nil,
                                    systemImage: "chart.bar.fill",
                                    songs: topPlayed,
                                    onTap: playSong
                                )
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
                .refreshable { computeSuggestions() }

                if player.currentSong != nil {
                    MiniPlayer(showNowPlaying: $showNowPlaying)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .animation(.spring(response: 0.38, dampingFraction: 0.85), value: player.currentSong != nil)
            .sheet(isPresented: $showNowPlaying) {
                SimpleNowPlayingView()
            }
        }
        .onAppear { computeSuggestions() }
        .onChange(of: library.songs.count) { _ in computeSuggestions() }
    }

    private func computeSuggestions() {
        let songs = library.songs
        suggestions = MusicRecommendationEngine.suggestions(from: songs)
        recentlyAdded = MusicRecommendationEngine.recentlyAdded(from: songs)
        topPlayed = MusicRecommendationEngine.topPlayed(from: songs)
    }

    private func playSong(_ song: Song) {
        let queue = library.songs
        let idx = queue.firstIndex(where: { $0.id == song.id }) ?? 0
        player.play(song: song, queue: queue, startIndex: idx)
        showNowPlaying = true
    }

    private var emptyLibraryPrompt: some View {
        VStack(spacing: 18) {
            Image(systemName: "music.note.list")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("Your Library is Empty")
                .font(.title2.bold())
            Text("Import songs from the Library tab to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Song Section Carousel

struct SongSectionCarousel: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let songs: [Song]
    let onTap: (Song) -> Void

    @StateObject private var player = MusicPlayerManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                    if let sub = subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            // Horizontal card carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(songs) { song in
                        SongCard(song: song, isPlaying: player.currentSong?.id == song.id && player.isPlaying)
                            .onTapGesture { onTap(song) }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }
}

// MARK: - Song Card

struct SongCard: View {
    let song: Song
    let isPlaying: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 140)

                if let data = song.artworkData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }

                if isPlaying {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 140, height: 140)
                    Image(systemName: "waveform")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 140, alignment: .leading)
                Text(song.artist)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 140, alignment: .leading)
            }
        }
    }
}
