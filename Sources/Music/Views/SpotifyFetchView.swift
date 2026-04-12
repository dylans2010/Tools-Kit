import SwiftUI

struct SpotifyFetchView: View {
    @StateObject private var viewModel = SpotifyFetchViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showLogs = false
    @State private var showFallbackFetch = false
    @State private var showThirdPartySheet = false
    @State private var thirdPartyVideoURL = ""
    @State private var thirdPartyResult: MP3Result?
    @State private var thirdPartyError: String?
    @State private var isThirdPartyLoading = false
    @AppStorage("zylaLabsAPIKey") private var zylaAPIKey = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isImporting || viewModel.isMatching || viewModel.isDownloading || viewModel.isExporting {
                    progressOverlay
                }

                VStack(spacing: 12) {
                    topSection
                    middleSection
                    bottomSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationTitle("Spotify Fetch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showLogs.toggle()
                    } label: {
                        Image(systemName: "terminal")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showLogs) {
                logView
            }
            .sheet(isPresented: $showFallbackFetch) {
                FallbackFetchView()
            }
            .sheet(isPresented: $showThirdPartySheet) {
                thirdPartyDownloadSheet
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

    private var progressOverlay: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.progressMessage)
                        .font(.caption.weight(.semibold))
                    ProgressView(value: viewModel.overallProgress)
                        .progressViewStyle(.linear)
                }

                Button {
                    viewModel.cancelCurrentTask()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
        }
    }

    private var topSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Paste Spotify Playlist URL", text: $viewModel.playlistURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)

                if !viewModel.playlistURL.isEmpty {
                    Button {
                        viewModel.playlistURL = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }

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
                    Text("Couldn’t parse playlist automatically. Paste tracks manually.")
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
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(viewModel.isImporting ? "Importing playlist..." : "Imported tracks will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    Section {
                        ForEach(viewModel.matchedTracks) { track in
                            trackRow(for: track)
                        }
                    } header: {
                        HStack {
                            Text("\(viewModel.matchedTracks.count) Tracks")
                            Spacer()
                            if viewModel.isMatching {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func trackRow(for track: MatchedTrack) -> some View {
        Button {
            viewModel.openSourceIfNeeded(for: track)
        } label: {
            HStack(spacing: 12) {
                statusIndicator(for: track)

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

                if let reason = track.reasonText {
                    Text(reason)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(track.reasonColor.opacity(0.15))
                        .foregroundColor(track.reasonColor)
                        .cornerRadius(4)
                }

                if track.sourceType == .external {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(track.sourceType != .external)
    }

    private var bottomSection: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.downloadAvailableTracks()
            } label: {
                if viewModel.isDownloading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Download Available Tracks", systemImage: "square.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.matchedTracks.isEmpty || viewModel.isMatching || viewModel.isDownloading || !viewModel.matchedTracks.contains(where: { $0.status == .matched }))

            HStack(spacing: 12) {
                Button {
                    viewModel.exportAsZIP()
                } label: {
                    if viewModel.isExporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Export ZIP", systemImage: "archivebox")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasDownloadedFiles || viewModel.isExporting)

                if let exportURL = viewModel.exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()
                .padding(.vertical, 4)

            Button {
                showFallbackFetch = true
            } label: {
                Label("Fallback Fetch (CSV Import)", systemImage: "arrow.down.doc.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if zylaAPIKey.isEmpty {
                Button {
                    thirdPartyVideoURL = ""
                    thirdPartyResult = nil
                    thirdPartyError = nil
                    showThirdPartySheet = true
                } label: {
                    Label("Download Without API Key", systemImage: "arrow.down.circle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding(.bottom, 10)
    }

    private var thirdPartyDownloadSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste a YouTube video URL below and download the highest-quality MP3 without needing a Zyla Labs API key.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    TextField("https://www.youtube.com/watch?v=...", text: $thirdPartyVideoURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                if let result = thirdPartyResult {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(result.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text("\(result.bitrate) kbps · \(result.size)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let downloadURL = URL(string: result.url) {
                            ShareLink(item: downloadURL) {
                                Label("Share MP3 Link", systemImage: "square.and.arrow.up")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                if let error = thirdPartyError {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task {
                        isThirdPartyLoading = true
                        thirdPartyResult = nil
                        thirdPartyError = nil
                        do {
                            thirdPartyResult = try await ThirdPartyAPI.getMP3Links(videoUrl: thirdPartyVideoURL)
                        } catch {
                            thirdPartyError = error.localizedDescription
                        }
                        isThirdPartyLoading = false
                    }
                } label: {
                    if isThirdPartyLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Fetch MP3 Link", systemImage: "arrow.down.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(thirdPartyVideoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isThirdPartyLoading)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .navigationTitle("Download Without API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showThirdPartySheet = false
                        thirdPartyVideoURL = ""
                        thirdPartyResult = nil
                        thirdPartyError = nil
                    }
                }
            }
        }
    }

    private var logView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption2, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                        Divider()
                    }
                }
            }
            .navigationTitle("Internal Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { showLogs = false }
                }
            }
        }
    }

    @ViewBuilder
    private func statusIndicator(for track: MatchedTrack) -> some View {
        switch track.status {
        case .queued:
            Circle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: "hourglass")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                )
        case .searching:
            ProgressView()
                .controlSize(.small)
                .frame(width: 20, height: 20)
        case .matched:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 20))
        case .downloaded:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
        case .failed:
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 20))
        }
    }
}

extension MatchedTrack {
    var reasonText: String? {
        switch reason {
        case .exact: return "EXACT"
        case .fuzzy: return "FUZZY"
        case .fallback: return "FALLBACK"
        case .none: return nil
        }
    }

    var reasonColor: Color {
        switch reason {
        case .exact: return .green
        case .fuzzy: return .blue
        case .fallback: return .orange
        case .none: return .secondary
        }
    }
}
