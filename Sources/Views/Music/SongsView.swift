import SwiftUI

struct SongRow: View {
    let song: Song
    let onTap: () -> Void

    @StateObject private var player = MusicPlayerManager.shared

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                artworkView
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
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var artworkView: some View {
        if let data = song.artworkData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .cornerRadius(8)
                .clipped()
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "music.note").foregroundColor(.secondary))
        }
    }
}

struct SongsView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var showImporter = false
    @State private var searchText = ""

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return library.songs }
        return library.songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            if library.songs.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filteredSongs) { song in
                        SongRow(song: song) {
                            let idx = filteredSongs.firstIndex(where: { $0.id == song.id }) ?? 0
                            player.play(song: song, queue: filteredSongs, startIndex: idx)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                library.deleteSong(song)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                player.addToQueue(song)
                            } label: {
                                Label("Add to Queue", systemImage: "text.badge.plus")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search songs")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showImporter = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showImporter) {
            FileImporterRepresentableView(allowedContentTypes: [.audio]) { urls in
                if let url = urls.first {
                    let accessing = url.startAccessingSecurityScopedResource()
                    library.importSong(from: url)
                    if accessing { url.stopAccessingSecurityScopedResource() }
                }
                showImporter = false
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Songs")
                .font(.title2.bold())
            Text("Tap + to import songs from your files.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
