import SwiftUI

struct CreatePlaylistView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedSongs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist Name") {
                    TextField("My Playlist", text: $name)
                }
                if !library.songs.isEmpty {
                    Section("Add Songs") {
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
                        library.createPlaylist(
                            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : name,
                            songIDs: Array(selectedSongs)
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
