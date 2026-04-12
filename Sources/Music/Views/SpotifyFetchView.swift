import SwiftUI
import UIKit

@MainActor
final class SpotifyFetchViewModel: ObservableObject {
    @Published var playlistURL: String = ""
    @Published var manualTrackInput: String = ""
    @Published var matchedTracks: [MatchedTrack] = []
    @Published var isImporting = false
    @Published var isDownloading = false
    @Published var isMatching = false
    @Published var showManualFallback = false
    @Published var errorMessage: String?
    @Published var exportURL: URL?
    @Published var hasDownloadedFiles = false

    private let fetchService = SpotifyFetchService()
    private let matchingService = TrackMatchingService()
    private let downloadManager = DownloadManager()
    private let zipExportService = ZipExportService()
    private let maxConcurrentMatches = 4

    func importPlaylist() {
        Task {
            isImporting = true
            errorMessage = nil
            showManualFallback = false
            matchedTracks = []

            do {
                let tracks = try await fetchService.fetchPlaylistTracks(from: playlistURL)
                await matchTracks(tracks)
            } catch {
                showManualFallback = true
                errorMessage = error.localizedDescription
            }

            isImporting = false
        }
    }

    func importManualTracks() {
        Task {
            let tracks = await fetchService.parseManualTrackList(manualTrackInput)
            guard !tracks.isEmpty else {
                errorMessage = "Add at least one track line in the format: Song - Artist"
                return
            }
            errorMessage = nil
            await matchTracks(tracks)
        }
    }

    func downloadAvailableTracks() {
        Task {
            isDownloading = true
            let saved = await downloadManager.downloadAvailableTracks(from: matchedTracks)
            if saved.isEmpty {
                errorMessage = "No direct local file URLs were available for download."
            } else {
                errorMessage = nil
            }
            hasDownloadedFiles = await downloadManager.hasDownloadedFiles()
            isDownloading = false
        }
    }

    func exportAsZIP() {
        do {
            exportURL = try zipExportService.exportDownloadedFilesAsPlaylistZip()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openSourceIfNeeded(for track: MatchedTrack) {
        guard track.sourceType == .external,
              let sourceURL = track.sourceURL,
              let url = URL(string: sourceURL) else {
            return
        }
        UIApplication.shared.open(url)
    }

    func refreshDownloadState() {
        Task {
            hasDownloadedFiles = await downloadManager.hasDownloadedFiles()
        }
    }

    private func matchTracks(_ tracks: [SpotifyTrack]) async {
        isMatching = true

        matchedTracks = tracks.map {
            MatchedTrack(
                original: $0,
                matchedTitle: nil,
                matchedArtist: nil,
                sourceType: .none,
                sourceURL: nil,
                confidence: 0,
                status: .searching
            )
        }

        let librarySongs = MusicLibraryManager.shared.songs

        for start in stride(from: 0, to: tracks.count, by: maxConcurrentMatches) {
            let end = min(start + maxConcurrentMatches, tracks.count)
            let chunk = Array(tracks[start..<end])

            let chunkResults = await withTaskGroup(of: (Int, MatchedTrack).self) { group in
                for (offset, track) in chunk.enumerated() {
                    let trackIndex = start + offset
                    group.addTask { [matchingService] in
                        let matched = matchingService.match(track: track, localSongs: librarySongs)
                        return (trackIndex, matched)
                    }
                }

                var results: [(Int, MatchedTrack)] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }

            for (index, matched) in chunkResults {
                guard matchedTracks.indices.contains(index) else { continue }
                matchedTracks[index] = matched
            }
        }

        isMatching = false
    }
}

struct SpotifyFetchView: View {
    @StateObject private var viewModel = SpotifyFetchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                topSection
                middleSection
                bottomSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .navigationTitle("Spotify Fetch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Spotify Fetch", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear { viewModel.refreshDownloadState() }
        }
    }

    private var topSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Paste Spotify Playlist URL", text: $viewModel.playlistURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .textFieldStyle(.roundedBorder)

            Button {
                viewModel.importPlaylist()
            } label: {
                Label("Import Playlist", systemImage: "arrow.down.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.playlistURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isImporting)

            if viewModel.showManualFallback {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Couldn’t parse playlist. Paste tracks manually (one per line: Song - Artist).")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    TextEditor(text: $viewModel.manualTrackInput)
                        .frame(minHeight: 90, maxHeight: 140)
                        .padding(8)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                    Button("Import Manual List") {
                        viewModel.importManualTracks()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var middleSection: some View {
        Group {
            if viewModel.matchedTracks.isEmpty {
                Spacer()
                Text(viewModel.isImporting ? "Importing playlist…" : "Imported tracks will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                List(viewModel.matchedTracks) { track in
                    Button {
                        viewModel.openSourceIfNeeded(for: track)
                    } label: {
                        HStack(spacing: 10) {
                            statusIndicator(for: track.status)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.original.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(track.original.artist)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if track.sourceType == .external {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(track.sourceType != .external)
                }
                .listStyle(.plain)
            }
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.downloadAvailableTracks()
            } label: {
                if viewModel.isDownloading || viewModel.isMatching {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Download Available Tracks")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.matchedTracks.isEmpty || viewModel.isMatching || viewModel.isDownloading)

            if let exportURL = viewModel.exportURL {
                ShareLink(item: exportURL) {
                    Text("Share playlist.zip")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button("Export as ZIP") {
                viewModel.exportAsZIP()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.hasDownloadedFiles)
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func statusIndicator(for status: MatchStatus) -> some View {
        switch status {
        case .searching:
            ProgressView()
                .controlSize(.small)
        case .matched:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.orange)
        }
    }
}
