import SwiftUI

struct PlaylistView: View {
    let playlist: Playlist
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var showAddSongs = false
    @State private var showCustomizeArtwork = false

    private var songs: [Song] { library.songs(for: playlist) }

    var body: some View {
        List {
            if songs.isEmpty {
                emptyState
            } else {
                ForEach(songs) { song in
                    SongRow(song: song) {
                        let idx = songs.firstIndex(where: { $0.id == song.id }) ?? 0
                        player.play(song: song, queue: songs, startIndex: idx)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { removeSong(song) } label: {
                            Label("Remove", systemImage: "minus.circle")
                        }
                    }
                }
                .onMove { moveSongs(from: $0, to: $1) }
            }
        }
        .listStyle(.plain)
        .navigationTitle(playlist.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showCustomizeArtwork = true
                    } label: {
                        Image(systemName: "paintbrush")
                    }
                    Button { showAddSongs = true } label: { Image(systemName: "plus") }
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showAddSongs) {
            AddSongsToPlaylistView(playlist: playlist)
        }
        .sheet(isPresented: $showCustomizeArtwork) {
            CustomizePlaylistArtwork(playlist: Binding(
                get: { library.playlists.first(where: { $0.id == playlist.id }) ?? playlist },
                set: { library.updatePlaylist($0) }
            ))
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No Songs")
                    .font(.headline)
                Text("Tap + to add songs.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            Spacer()
        }
        .listRowBackground(Color.clear)
    }

    private func removeSong(_ song: Song) {
        var updated = playlist
        updated.songIDs.removeAll { $0 == song.id }
        library.updatePlaylist(updated)
    }

    private func moveSongs(from source: IndexSet, to destination: Int) {
        var updated = playlist
        updated.songIDs.move(fromOffsets: source, toOffset: destination)
        library.updatePlaylist(updated)
    }
}

struct AddSongsToPlaylistView: View {
    let playlist: Playlist
    @StateObject private var library = MusicLibraryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List(library.songs) { song in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title).font(.subheadline)
                        Text(song.artist).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if selected.contains(song.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selected.contains(song.id) { selected.remove(song.id) }
                    else { selected.insert(song.id) }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        var updated = playlist
                        for id in selected where !updated.songIDs.contains(id) {
                            updated.songIDs.append(id)
                        }
                        library.updatePlaylist(updated)
                        dismiss()
                    }
                    .disabled(selected.isEmpty)
                }
            }
            .onAppear { selected = Set(playlist.songIDs) }
        }
    }
}
