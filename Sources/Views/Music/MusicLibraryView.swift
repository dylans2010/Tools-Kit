import SwiftUI

struct MusicLibraryView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @StateObject private var modeManager = MusicModeManager.shared
    @State private var selectedTab: MusicTab = .songs
    @State private var showNowPlaying = false
    @State private var showSettings = false

    enum MusicTab: String, CaseIterable {
        case songs = "Songs"
        case playlists = "Playlists"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        ForEach(MusicTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Group {
                        switch selectedTab {
                        case .songs:
                            SongsView()
                        case .playlists:
                            PlaylistsListView()
                        }
                    }
                }
                .navigationTitle("Music")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    MusicSettingsView()
                }
            }

            if player.currentSong != nil {
                MiniPlayer(showNowPlaying: $showNowPlaying)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
    }
}

// MARK: - Playlists tab

struct PlaylistsListView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @State private var showCreate = false

    var body: some View {
        ZStack {
            if library.playlists.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(library.playlists) { playlist in
                        NavigationLink(destination: PlaylistView(playlist: playlist)) {
                            HStack(spacing: 14) {
                                artworkThumbnail(for: playlist)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playlist.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(library.songs(for: playlist).count) songs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
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
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreatePlaylistView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Playlists")
                .font(.title2.bold())
            Text("Tap + to create a playlist.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    @ViewBuilder
    private func artworkThumbnail(for playlist: Playlist) -> some View {
        if let id = playlist.artworkSongID,
           let song = library.song(by: id),
           let data = song.artworkData,
           let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .cornerRadius(8)
                .clipped()
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "music.note.list").foregroundColor(.secondary))
        }
    }
}
