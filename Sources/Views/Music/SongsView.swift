import SwiftUI
import UniformTypeIdentifiers

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
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
            if let data = song.artworkData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .clipped()
    }
}

struct SongsView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var searchText = ""

    // Import sheet state
    @State private var showImportPicker = false
    @State private var showSingleImporter = false
    @State private var showZIPImporter = false
    @State private var isImportingZIP = false

    // ZIP → playlist prompt state
    @State private var zipImportedSongs: [Song] = []
    @State private var showZIPPlaylistAlert = false
    @State private var showPlaylistNameAlert = false
    @State private var pendingPlaylistName = ""
    @State private var showRenameAlert = false
    @State private var renameTargetSongID: UUID?
    @State private var pendingSongName = ""

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
                            Button {
                                renameTargetSongID = song.id
                                pendingSongName = song.title
                                showRenameAlert = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.gray)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search songs")
            }

            // ZIP import progress overlay
            if isImportingZIP {
                Color(.systemBackground).opacity(0.85)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("Importing from ZIP…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showImportPicker = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // Import type selection sheet
        .sheet(isPresented: $showImportPicker) {
            importPickerSheet
        }
        // Single song file importer
        .sheet(isPresented: $showSingleImporter) {
            FileImporterRepresentableView(
                allowedContentTypes: [.audio, .mp3,
                    UTType(filenameExtension: "m4a") ?? .audio,
                    UTType(filenameExtension: "aac") ?? .audio,
                    UTType(filenameExtension: "wav") ?? .audio,
                    UTType(filenameExtension: "flac") ?? .audio]
            ) { urls in
                showSingleImporter = false
                guard let url = urls.first else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                library.importSong(from: url)
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
        }
        // ZIP file importer
        .sheet(isPresented: $showZIPImporter) {
            FileImporterRepresentableView(
                allowedContentTypes: [UTType(filenameExtension: "zip") ?? .data]
            ) { urls in
                showZIPImporter = false
                guard let url = urls.first else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                isImportingZIP = true
                Task {
                    let imported = await library.importFromZIP(at: url)
                    if accessing { url.stopAccessingSecurityScopedResource() }
                    await MainActor.run {
                        isImportingZIP = false
                        if !imported.isEmpty {
                            zipImportedSongs = imported
                            showZIPPlaylistAlert = true
                        }
                    }
                }
            }
        }
        // Ask whether to turn the imported songs into a playlist
        .alert("Create Playlist?", isPresented: $showZIPPlaylistAlert) {
            Button("Yes") {
                pendingPlaylistName = ""
                showPlaylistNameAlert = true
            }
            Button("No", role: .cancel) {
                zipImportedSongs = []
            }
        } message: {
            let count = zipImportedSongs.count
            Text("Would you like to add \(count) imported \(count == 1 ? "song" : "songs") to a new playlist?")
        }
        // Collect the playlist name then create it
        .alert("Name Your Playlist", isPresented: $showPlaylistNameAlert) {
            TextField("Playlist Name", text: $pendingPlaylistName)
            Button("Create") {
                let name = pendingPlaylistName.trimmingCharacters(in: .whitespaces)
                library.createPlaylist(
                    name: name.isEmpty ? "Imported Playlist" : name,
                    songIDs: zipImportedSongs.map(\.id)
                )
                zipImportedSongs = []
                pendingPlaylistName = ""
            }
            Button("Cancel", role: .cancel) {
                zipImportedSongs = []
                pendingPlaylistName = ""
            }
        } message: {
            Text("Enter a name for your new playlist.")
        }
        .alert("Rename Song", isPresented: $showRenameAlert) {
            TextField("Song Name", text: $pendingSongName)
            Button("Save") {
                guard let id = renameTargetSongID else { return }
                library.renameSong(id: id, newTitle: pendingSongName)
                renameTargetSongID = nil
                pendingSongName = ""
            }
            Button("Cancel", role: .cancel) {
                renameTargetSongID = nil
                pendingSongName = ""
            }
        } message: {
            Text("Enter a new song name.")
        }
    }

    // MARK: - Import Picker Sheet

    private var importPickerSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text("Import Music")
                .font(.headline)
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                importOption(
                    title: "Single Song",
                    subtitle: "Add one audio file from your Files",
                    icon: "music.note",
                    color: .blue
                ) {
                    showImportPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        showSingleImporter = true
                    }
                }

                importOption(
                    title: "ZIP File",
                    subtitle: "Extract all MP3 & MP4 files from a ZIP archive",
                    icon: "doc.zipper",
                    color: .orange
                ) {
                    showImportPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        showZIPImporter = true
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.hidden)
    }

    private func importOption(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Songs")
                .font(.title2.bold())
            Text("Tap + to import songs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
