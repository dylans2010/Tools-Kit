import SwiftUI

struct CreatePlaylistView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedSongs: Set<UUID> = []
    @State private var draftPlaylist: Playlist?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("My Playlist", text: $name)
                } header: {
                    Text("Playlist Name")
                }

                Section {
                    Button {
                        openArtworkCustomizer()
                    } label: {
                        Label("Customize Playlist Artwork", systemImage: "paintbrush.pointed")
                    }
                } header: {
                    Text("Artwork")
                }

                if !library.songs.isEmpty {
                    Section {
                        ForEach(library.songs) { song in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title).font(.subheadline)
                                    Text(song.artist).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedSongs.contains(song.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSongs.contains(song.id) { selectedSongs.remove(song.id) }
                                else { selectedSongs.insert(song.id) }
                            }
                        }
                    } header: {
                        Text("Add Songs")
                    }
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let created = library.createPlaylist(
                            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : name,
                            songIDs: Array(selectedSongs)
                        )
                        if let customArtworkData = draftPlaylist?.customArtworkData {
                            var updated = created
                            updated.customArtworkData = customArtworkData
                            library.updatePlaylist(updated)
                        }
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $draftPlaylist) { playlist in
            CustomizePlaylistArtwork(playlist: Binding(
                get: { draftPlaylist ?? playlist },
                set: { draftPlaylist = $0 }
            ))
        }
    }

    private func openArtworkCustomizer() {
        let resolvedName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : name
        var playlist: Playlist
        if let existingDraft = draftPlaylist {
            playlist = existingDraft
            playlist.name = resolvedName
            playlist.songIDs = Array(selectedSongs)
        } else {
            playlist = Playlist(name: resolvedName, songIDs: Array(selectedSongs))
        }
        if playlist.artworkSongID == nil || !(playlist.artworkSongID.map(selectedSongs.contains) ?? false) {
            playlist.artworkSongID = playlist.songIDs.first
        }
        draftPlaylist = playlist
    }
}
