import SwiftUI

struct MusicSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var searchText: String = ""
    @State private var showNowPlaying = false
    @State private var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "music.recentSearches") ?? []

    private var filteredSongs: [Song] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return library.songs }
        return library.songs.filter {
            $0.title.lowercased().contains(query) ||
            $0.artist.lowercased().contains(query)
        }
    }

    private var groupedByArtist: [(String, [Song])] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        let dict = Dictionary(grouping: filteredSongs, by: \.artist)
        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Group {
                    if library.songs.isEmpty {
                        emptyState(
                            icon: "music.note.list",
                            title: "No Songs Yet",
                            subtitle: "Import songs from the Library tab.")
                    } else if !searchText.isEmpty && filteredSongs.isEmpty {
                        emptyState(
                            icon: "magnifyingglass",
                            title: "No Results",
                            subtitle: "Try a different title or artist name.")
                    } else if searchText.isEmpty {
                        browseGrid
                    } else {
                        searchResults
                    }
                }

                if player.currentSong != nil {
                    MiniPlayer(showNowPlaying: $showNowPlaying)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Songs or Artists")
            .onSubmit(of: .search) {
                addToRecentSearches(searchText)
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.85), value: player.currentSong != nil)
            .sheet(isPresented: $showNowPlaying) {
                SimpleNowPlayingView()
            }
        }
    }

    // MARK: - Browse Grid (no query)

    private var browseGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                if !recentSearches.isEmpty {
                    recentSearchesSection
                }

                artistSection

                suggestedArtistsSection
            }
            .padding(.top, 12)
            .padding(.bottom, 90)
        }
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button("Clear") {
                    recentSearches.removeAll()
                    UserDefaults.standard.set([], forKey: "music.recentSearches")
                }
                .font(.caption.bold())
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentSearches, id: \.self) { query in
                        Button {
                            searchText = query
                        } label: {
                            Text(query)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var suggestedArtistsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested Artists")
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal)

            let allArtists = Set(library.songs.map(\.artist))
            let suggested = allArtists.shuffled().prefix(5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(suggested), id: \.self) { artist in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 80, height: 80)
                                if let art = library.songs.first(where: { $0.artist == artist })?.artworkData,
                                   let img = UIImage(data: art) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Text(artist)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                                .frame(width: 80)
                        }
                        .onTapGesture {
                            searchText = artist
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var artistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("All Artists")
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal)

            let artists = Array(Set(library.songs.map(\.artist))).sorted()
            ForEach(artists, id: \.self) { artist in
                let artistSongs = library.songs.filter { $0.artist == artist }
                artistRow(artist: artist, songs: artistSongs)
                Divider().padding(.leading, 68)
            }
        }
    }

    private func artistRow(artist: String, songs: [Song]) -> some View {
        Button {
            if let first = songs.first {
                play(first, in: songs)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                    if let art = songs.first?.artworkData, let img = UIImage(data: art) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(artist)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("\(songs.count) Song\(songs.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Results

    private var searchResults: some View {
        List {
            if groupedByArtist.count > 1 {
                ForEach(groupedByArtist, id: \.0) { artist, songs in
                    Section(artist) {
                        ForEach(songs) { song in
                            songRow(song, in: filteredSongs)
                        }
                    }
                }
            } else {
                ForEach(filteredSongs) { song in
                    songRow(song, in: filteredSongs)
                }
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: player.currentSong != nil ? 80 : 0)
        }
    }

    private func songRow(_ song: Song, in queue: [Song]) -> some View {
        Button {
            play(song, in: queue)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(.systemGray5))
                    if let data = song.artworkData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .padding(2)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 44, height: 44)
                .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if player.currentSong?.id == song.id && player.isPlaying {
                    Image(systemName: "waveform")
                        .foregroundColor(.accentColor)
                }
                Text(song.formattedDuration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Playback

    private func play(_ song: Song, in queue: [Song]) {
        let idx = queue.firstIndex(where: { $0.id == song.id }) ?? 0
        player.play(song: song, queue: queue, startIndex: idx)
        showNowPlaying = true
        addToRecentSearches(song.title)
    }

    private func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var searches = recentSearches
        if let existing = searches.firstIndex(of: trimmed) {
            searches.remove(at: existing)
        }
        searches.insert(trimmed, at: 0)
        if searches.count > 10 { searches.removeLast() }

        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "music.recentSearches")
    }
}
