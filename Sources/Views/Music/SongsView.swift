import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

// MARK: - SongRow

struct SongRow: View {
    let song: Song
    let onTap: () -> Void

    @StateObject private var player = MusicPlayerManager.shared

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
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
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var artworkView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(.systemGray5))
            if let data = song.artworkData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(2)
            } else {
                Image(systemName: "music.note")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 40, height: 40)
        .clipped()
        .cornerRadius(7)
    }
}

// MARK: - SongsView

struct SongsView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @StateObject private var player = MusicPlayerManager.shared
    @State private var searchText = ""
    @State private var selectedSort: SortOption = .dateAdded
    @State private var showImportPicker = false
    @State private var showSingleImporter = false
    @State private var showZIPImporter = false
    @State private var isImportingZIP = false
    @State private var pendingZIPURL: URL?
    @State private var pendingZIPSecurityScoped = false
    @State private var showZIPNameAlert = false
    @State private var pendingPlaylistName = ""
    @State private var showRenameAlert = false
    @State private var renameTargetSongID: UUID?
    @State private var pendingSongName = ""

    enum SortOption: String, CaseIterable {
        case dateAdded = "Recently Added"
        case title     = "Title"
        case artist    = "Artist"
        case playCount = "Most Played"
    }

    private var filteredSongs: [Song] {
        let base = searchText.isEmpty ? library.songs : library.songs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
        switch selectedSort {
        case .dateAdded: return base.sorted { $0.dateAdded > $1.dateAdded }
        case .title:     return base.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .artist:    return base.sorted { $0.artist.localizedCompare($1.artist) == .orderedAscending }
        case .playCount: return base.sorted { $0.playCount > $1.playCount }
        }
    }

    var body: some View {
        ZStack {
            if library.songs.isEmpty {
                emptyState
            } else {
                List {
                    // Activity header (not shown when searching)
                    if searchText.isEmpty {
                        Section {
                            activityHeader
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }

                    // Sort bar
                    Section {
                        sortBar
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    // Song rows
                    Section {
                        ForEach(filteredSongs) { song in
                            SongRow(song: song) {
                                let playable = filteredSongs.filter {
                                    $0.fileURL.isFileURL && FileManager.default.fileExists(atPath: $0.fileURL.path)
                                }
                                guard let target = playable.first(where: { $0.id == song.id }) else { return }
                                let idx = playable.firstIndex(where: { $0.id == target.id }) ?? 0
                                // Always set the full playable queue to ensure predictable ordering
                                player.play(song: target, queue: playable, startIndex: idx)
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
                    } header: {
                        Text("\(filteredSongs.count) Songs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search songs")
            }

            if isImportingZIP {
                Color(.systemBackground).opacity(0.85)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.4)
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
        .sheet(isPresented: $showImportPicker) { importPickerSheet }
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
        .sheet(isPresented: $showZIPImporter) {
            FileImporterRepresentableView(
                allowedContentTypes: [UTType(filenameExtension: "zip") ?? .data]
            ) { urls in
                showZIPImporter = false
                guard let url = urls.first else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                pendingZIPURL = url
                pendingZIPSecurityScoped = accessing
                // Pre-fill name from the ZIP filename (without extension)
                pendingPlaylistName = url.deletingPathExtension().lastPathComponent
                showZIPNameAlert = true
            }
        }
        .alert("Name Your Playlist", isPresented: $showZIPNameAlert) {
            TextField("Playlist Name", text: $pendingPlaylistName)
            Button("Import") {
                guard let zipURL = pendingZIPURL else { return }
                let name = pendingPlaylistName.trimmingCharacters(in: .whitespaces)
                let secured = pendingZIPSecurityScoped
                pendingZIPURL = nil
                pendingZIPSecurityScoped = false
                pendingPlaylistName = ""
                isImportingZIP = true
                Task {
                    defer {
                        if secured { zipURL.stopAccessingSecurityScopedResource() }
                    }
                    await library.importFromZIP(at: zipURL, playlistName: name.isEmpty ? "Imported Playlist" : name)
                    await MainActor.run { isImportingZIP = false }
                }
            }
            Button("Cancel", role: .cancel) {
                if pendingZIPSecurityScoped { pendingZIPURL?.stopAccessingSecurityScopedResource() }
                pendingZIPURL = nil
                pendingZIPSecurityScoped = false
                pendingPlaylistName = ""
            }
        } message: {
            Text("Enter a name for the new playlist that will be created from this ZIP file.")
        }
        .alert("Rename Song", isPresented: $showRenameAlert) {
            TextField("Song Name", text: $pendingSongName)
            Button("Save") {
                guard let id = renameTargetSongID else { return }
                library.renameSong(id: id, newTitle: pendingSongName)
                renameTargetSongID = nil; pendingSongName = ""
            }
            .disabled(pendingSongName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { renameTargetSongID = nil; pendingSongName = "" }
        } message: { Text("Enter a new song name.") }
    }

    // MARK: - Activity Header

    private var activityHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                activityCard(
                    title: "Songs",
                    value: "\(library.songs.count)",
                    icon: "music.note",
                    color: .blue
                )
                activityCard(
                    title: "Played",
                    value: "\(totalPlays)",
                    icon: "play.circle.fill",
                    color: .green
                )
                activityCard(
                    title: "Favorites",
                    value: topArtist,
                    icon: "star.fill",
                    color: .orange
                )
                if let top = topSong {
                    activityCard(
                        title: "Top Song",
                        value: top.title,
                        icon: "crown.fill",
                        color: .purple
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func activityCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minWidth: 110, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var totalPlays: Int { library.songs.reduce(0) { $0 + $1.playCount } }
    private var topArtist: String {
        let counts = Dictionary(grouping: library.songs, by: \.artist)
            .mapValues { $0.reduce(0) { $0 + $1.playCount } }
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }
    private var topSong: Song? {
        let best = library.songs.max(by: { $0.playCount < $1.playCount })
        return best.flatMap { $0.playCount > 0 ? $0 : nil }
    }

    // MARK: - Sort Bar

    private var sortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SortOption.allCases, id: \.self) { opt in
                    let selected = selectedSort == opt
                    Button { withAnimation { selectedSort = opt } } label: {
                        Text(opt.rawValue)
                            .font(.system(size: 13, weight: selected ? .semibold : .regular))
                            .foregroundColor(selected ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Import Picker

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
                importOption(title: "Single Song",
                             subtitle: "Add one audio file from your Files",
                             icon: "music.note", color: .blue) {
                    showImportPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { showSingleImporter = true }
                }
                importOption(title: "ZIP File",
                             subtitle: "Extract all audio files from a ZIP archive",
                             icon: "doc.zipper", color: .orange) {
                    showImportPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { showZIPImporter = true }
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.hidden)
    }

    private func importOption(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
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
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                    Text(subtitle).font(.system(size: 13)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.secondary)
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
