import SwiftUI

struct MusicLibraryView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @StateObject private var modeManager = MusicModeManager.shared
    @State private var selectedTab: MusicTab = .songs
    @State private var showNowPlaying = false
    @State private var showSettings = false
    @State private var showEqualizer = false
    @State private var showAudioControls = false

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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .navigationTitle("Music")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showAudioControls = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        Button {
                            showEqualizer = true
                        } label: {
                            Image(systemName: "waveform.path.ecg")
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    MusicSettingsView()
                }
                .sheet(isPresented: $showEqualizer) {
                    EqualizerView()
                }
                .sheet(isPresented: $showAudioControls) {
                    AudioControlsView()
                }
            }
            // Reserve space so list content doesn't scroll under the mini player
            .safeAreaInset(edge: .bottom) {
                if player.currentSong != nil {
                    Color.clear.frame(height: 72)
                }
            }

            // Mini player pinned above safe-area bottom
            if player.currentSong != nil {
                MiniPlayer(showNowPlaying: $showNowPlaying)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: player.currentSong != nil)
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView()
        }
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
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                library.deletePlaylist(playlist)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                playlistToCustomize = playlist
                            } label: {
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
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreatePlaylistView()
        }
        .sheet(item: $playlistToCustomize) { playlist in
            CustomizePlaylistArtwork(playlist: Binding(
                get: { library.playlists.first(where: { $0.id == playlist.id }) ?? playlist },
                set: { library.updatePlaylist($0) }
            ))
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
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
            if let data = playlist.customArtworkData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if let id = playlist.artworkSongID,
               let song = library.song(by: id),
               let data = song.artworkData,
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note.list")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 48, height: 48)
        .clipped()
    }
}
