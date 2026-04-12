import SwiftUI
import UniformTypeIdentifiers

struct FallbackFetchView: View {
    @StateObject private var viewModel = FallbackFetchViewModel()
    @State private var showingImporter = false

    var body: some View {
        ToolDetailView(tool: FallbackFetchTool()) {
            VStack(spacing: 20) {
                // API Key Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zyla Labs API Key")
                        .font(.headline)

                    SecureField("Enter your API Key", text: $viewModel.apiKey)
                        .textFieldStyle(.roundedBorder)

                    Link("Get your API Key here", destination: URL(string: "https://zylalabs.com/api-marketplace/music+%26+audio/youtube+to+audio+api/381")!)
                        .font(.footnote)
                        .foregroundColor(.blue)
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
                            if viewModel.isProcessing {
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

                                        statusView(for: song.status)
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.startFetching()
                        }
                    }) {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Start Fetching")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.songs.isEmpty || viewModel.apiKey.isEmpty || viewModel.isProcessing ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(viewModel.songs.isEmpty || viewModel.apiKey.isEmpty || viewModel.isProcessing)

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
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importCSV(url: url)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
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
