import SwiftUI

struct MusicLibraryView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var selectedTab: LibrarySection = .songs
    @State private var showNowPlaying = false
    @State private var showSettings = false
    @State private var showImport = false

    enum LibrarySection: String, CaseIterable, Identifiable {
        case songs = "Songs"
        case artists = "Artists"
        case albums = "Albums"
        case playlists = "Playlists"
        var id: String { self.rawValue }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                VStack(spacing: 0) {
                    // Segmented Picker Style Tabs
                    HStack(spacing: 0) {
                        ForEach(LibrarySection.allCases) { section in
                            VStack(spacing: 8) {
                                Text(section.rawValue)
                                    .font(.system(size: 14, weight: selectedTab == section ? .bold : .medium))
                                    .foregroundColor(selectedTab == section ? .accentColor : .secondary)

                                Rectangle()
                                    .fill(selectedTab == section ? Color.accentColor : Color.clear)
                                    .frame(height: 2)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedTab = section
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 10)
                    .background(Color(uiColor: .systemBackground))

                    Divider()

                    TabView(selection: $selectedTab) {
                        SongsView()
                            .tag(LibrarySection.songs)
                        ArtistsView()
                            .tag(LibrarySection.artists)
                        AlbumsView()
                            .tag(LibrarySection.albums)
                        PlaylistsListView()
                            .tag(LibrarySection.playlists)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .navigationTitle("Library")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Button { showImport = true } label: {
                                Image(systemName: "plus.circle")
                            }
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    MusicSettingsView()
                }
                .sheet(isPresented: $showImport) {
                    ImportMusicView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if player.currentSong != nil {
                    Color.clear.frame(height: 72)
                }
            }

            if player.currentSong != nil {
                MiniPlayer(showNowPlaying: $showNowPlaying)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: player.currentSong != nil)
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }
}

// MARK: - Artists View

struct ArtistsView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var showNowPlaying = false

    private var artistGroups: [(name: String, songs: [Song])] {
        let grouped = Dictionary(grouping: library.songs, by: { $0.artist.isEmpty ? "Unknown Artist" : $0.artist })
        return grouped.map { (name: $0.key, songs: $0.value) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        if artistGroups.isEmpty {
            emptyState(icon: "person.2", message: "No Artists")
        } else {
            List(artistGroups, id: \.name) { group in
                NavigationLink(destination: ArtistSongsView(artistName: group.name, songs: group.songs)) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 48, height: 48)
                            if let artwork = group.songs.first(where: { $0.artworkData != nil })?.artworkData,
                               let img = UIImage(data: artwork) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name)
                                .font(.subheadline.weight(.semibold))
                            Text("\(group.songs.count) \(group.songs.count == 1 ? "Song" : "Songs")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Artist Songs View

struct ArtistSongsView: View {
    let artistName: String
    let songs: [Song]
    @StateObject private var player = MusicPlayerManager.shared
    @State private var showNowPlaying = false

    var body: some View {
        List(songs) { song in
            Button {
                let idx = songs.firstIndex(where: { $0.id == song.id }) ?? 0
                player.play(song: song, queue: songs, startIndex: idx)
                showNowPlaying = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(width: 40, height: 40)
                        if let data = song.artworkData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(song.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if player.currentSong?.id == song.id {
                        Image(systemName: player.isPlaying ? "waveform" : "pause.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle(artistName)
        .sheet(isPresented: $showNowPlaying) { NowPlayingView() }
    }
}

// MARK: - Albums View (grouped by playlistName as album proxy)

struct AlbumsView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var showNowPlaying = false

    private var albums: [(name: String, artist: String, songs: [Song])] {
        let grouped = Dictionary(grouping: library.songs, by: { song -> String in
            song.playlistName ?? "Library"
        })
        return grouped.map { key, songs in
            let artist = songs.map(\.artist).first(where: { !$0.isEmpty }) ?? "Unknown"
            return (name: key, artist: artist, songs: songs)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        if albums.isEmpty {
            emptyState(icon: "square.stack", message: "No Albums")
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albums, id: \.name) { album in
                        NavigationLink(destination: AlbumSongsView(albumName: album.name, songs: album.songs)) {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                    if let data = album.songs.first(where: { $0.artworkData != nil })?.artworkData,
                                       let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        Image(systemName: "square.stack.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)

                                Text(album.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(album.artist)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Album Songs View

struct AlbumSongsView: View {
    let albumName: String
    let songs: [Song]
    @StateObject private var player = MusicPlayerManager.shared
    @State private var showNowPlaying = false

    var body: some View {
        List(songs) { song in
            Button {
                let idx = songs.firstIndex(where: { $0.id == song.id }) ?? 0
                player.play(song: song, queue: songs, startIndex: idx)
                showNowPlaying = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(width: 40, height: 40)
                        if let data = song.artworkData, let img = UIImage(data: data) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Image(systemName: "music.note").font(.system(size: 14)).foregroundColor(.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title).font(.subheadline.weight(.semibold)).foregroundColor(.primary).lineLimit(1)
                        Text(song.artist).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    }
                    Spacer()
                    if player.currentSong?.id == song.id {
                        Image(systemName: player.isPlaying ? "waveform" : "pause.fill")
                            .font(.system(size: 13)).foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle(albumName)
        .sheet(isPresented: $showNowPlaying) { NowPlayingView() }
    }
}

// MARK: - Playlists tab

struct PlaylistsListView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @State private var showCreate = false
    @State private var playlistToCustomize: Playlist?

    var body: some View {
        ZStack {
            if library.playlists.isEmpty {
                emptyState(icon: "music.note.list", message: "No Playlists")
            } else {
                List {
                    ForEach(library.playlists) { playlist in
                        NavigationLink(destination: PlaylistView(playlist: playlist)) {
                            HStack(spacing: 14) {
                                artworkThumbnail(for: playlist)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playlist.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(library.songs(for: playlist).count) Songs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                library.deletePlaylist(playlist)
                            } label: { Label("Delete", systemImage: "trash") }
                            Button { playlistToCustomize = playlist } label: {
                                Label("Customize", systemImage: "paintbrush")
                            }
                            .tint(.purple)
                        }
                    }
                    .onDelete { offsets in
                        offsets.forEach { library.deletePlaylist(library.playlists[$0]) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showCreate) { CreatePlaylistView() }
        .sheet(item: $playlistToCustomize) { playlist in
            CustomizePlaylistArtwork(playlist: Binding(
                get: { library.playlists.first(where: { $0.id == playlist.id }) ?? playlist },
                set: { library.updatePlaylist($0) }
            ))
        }
    }

    @ViewBuilder
    private func artworkThumbnail(for playlist: Playlist) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5))
            if let data = playlist.customArtworkData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity).padding(2)
            } else if let id = playlist.artworkSongID, let song = library.song(by: id),
                      let data = song.artworkData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity).padding(2)
            } else {
                Image(systemName: "music.note.list").foregroundColor(.secondary)
            }
        }
        .frame(width: 48, height: 48).clipped()
    }
}

// MARK: - Shared empty state

@ViewBuilder
private func emptyState(icon: String, message: String) -> some View {
    VStack(spacing: 16) {
        Image(systemName: icon).font(.system(size: 48)).foregroundColor(.secondary)
        Text(message).font(.title2.bold())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
}
