import SwiftUI
import UniformTypeIdentifiers

struct FallbackFetchView: View {
    @StateObject private var viewModel = FallbackFetchViewModel()
    @State private var showingImporter = false
    @ObservedObject private var logger = LogManager.shared

    var body: some View {
        ToolDetailView(tool: FallbackFetchTool()) {
            VStack(spacing: 20) {
                // API Keys Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("API Keys")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("YouTube Data API Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        SecureField("Enter your YouTube Data API Key", text: $viewModel.youtubeAPIKey)
                            .textFieldStyle(.roundedBorder)
        Link("Get a YouTube Data API Key", destination: URL(string: "https://console.cloud.google.com/apis/library/youtube.googleapis.com") ?? URL(string: "https://console.cloud.google.com")!)
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Zyla Labs API Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        SecureField("Enter your Zyla Labs API Key", text: $viewModel.zylaAPIKey)
                            .textFieldStyle(.roundedBorder)
                        Link("Get a Zyla Labs API Key", destination: URL(string: "https://zylalabs.com/api-marketplace/music+%26+audio/youtube+to+audio+api/381") ?? URL(string: "https://zylalabs.com")!)
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // CSV Import Section
                VStack(spacing: 12) {
                    Text("Import your playlist CSV from [Exportify](https://exportify.app)")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)

                    Button(action: { showingImporter = true }) {
                        Label("Select CSV File", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                if !viewModel.songs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Playlist (\(viewModel.songs.count) songs)")
                                .font(.headline)
                            Spacer()
                            if viewModel.isFetching {
                                ProgressView(value: viewModel.overallProgress)
                                    .frame(width: 100)
                            }
                        }

                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.songs) { song in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(song.title)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            Text(song.artist)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 4) {
                                            statusView(for: song.status)
                                            if let url = song.youtubeURL {
                                                Text("YT: \(url)")
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            if let download = song.downloadURL {
                                                Text(download.lastPathComponent)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }

                // Actions + Logs
                VStack(spacing: 12) {
                    Button(action: {
                        Task { await viewModel.startFetching() }
                    }) {
                        if viewModel.isFetching {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Start Fetching")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canStartFetching ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!viewModel.canStartFetching)

                    if let zipURL = viewModel.zipURL {
                        ShareLink(item: zipURL) {
                            Label("Download Songs.zip", systemImage: "square.and.arrow.up")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }

                    InternalLogsView(logger: logger)
                        .frame(maxHeight: 260)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingImporter) {
            FileImporterRepresentableView(
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { urls in
                showingImporter = false
                if let url = urls.first {
                    viewModel.importCSV(url: url)
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    @ViewBuilder
    private func statusView(for status: FetchStatus) -> some View {
        switch status {
        case .idle:
            Image(systemName: "circle")
                .foregroundColor(.gray)
        case .searching, .ranking, .fetchingAudio, .downloading:
            ProgressView()
                .scaleEffect(0.7)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed(let reason):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .help(reason)
        }
    }
}

struct FallbackFetchTool: Tool {
    let name = "Fallback Fetch"
    let icon = "arrow.down.doc.fill"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Import a playlist CSV and download songs as high-quality MP3s in a ZIP file."
    let requiresAPI = true
    var view: AnyView { AnyView(FallbackFetchView()) }
}

struct FallbackFetchView_Previews: PreviewProvider {
    static var previews: some View {
        FallbackFetchView()
    }
}

// MARK: - Logs UI

private struct InternalLogsView: View {
    @ObservedObject var logger: LogManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Internal Logs")
                    .font(.headline)
                Spacer()
                Button("Clear") { logger.clear() }
                    .font(.caption)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(logger.entries) { entry in
                            FallbackFetchLogEntryRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: logger.entries.count) { _, _ in
                    if let last = logger.entries.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
        .padding()
    }
}

private struct FallbackFetchLogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(entry.level.emoji)
                Text("[\(entry.stage.rawValue)]")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(entry.formattedTimestamp)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            Text(entry.message)
                .font(.subheadline)
            if let metadata = entry.metadata, !metadata.isEmpty {
                Text(metadata.map { "\($0.key): \($0.value)" }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(6)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}
