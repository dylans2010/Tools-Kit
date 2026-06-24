import SwiftUI

struct HFModelDetailView: View {
    let modelId: String
    @State private var model: HFModel?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @ObservedObject var downloadManager = HuggingFaceDownloadManager.shared

    @State private var totalSize: Int64?

    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading model details...")
                        Spacer()
                    }
                }
            } else if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            } else if let model = model {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(model.id)
                            .font(.title3.bold())

                        if let author = model.author {
                            Text("by \(author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Stats") {
                    HStack {
                        Label("\(model.downloads ?? 0)", systemImage: "arrow.down.circle")
                        Spacer()
                        Label("\(model.likes ?? 0)", systemImage: "heart")
                    }
                }

                if let tags = model.tags, !tags.isEmpty {
                    Section("Tags") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                Section("Download & Size") {
                    if let size = totalSize {
                        HStack {
                            Text("Estimated Total Size")
                            Spacer()
                            Text(formatSize(size))
                                .foregroundColor(.secondary)
                        }
                    }

                    if let downloadTask = downloadManager.activeDownloads[model.id] {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(downloadTask.status.rawValue.capitalized)
                                    .font(.subheadline.bold())
                                Spacer()
                                if downloadTask.status == .downloading {
                                    Text("\(Int(downloadTask.progress * 100))%")
                                        .font(.caption)
                                }
                            }

                            if downloadTask.status == .downloading {
                                ProgressView(value: downloadTask.progress)

                                HStack {
                                    Text(formatSize(downloadTask.bytesReceived))
                                    Text("/")
                                    Text(formatSize(downloadTask.totalBytes))
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)

                                Button(role: .destructive) {
                                    downloadManager.cancelDownload(id: model.id)
                                } label: {
                                    Text("Cancel Download")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            } else if downloadTask.status == .completed {
                                Text("Model is ready to use.")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    } else {
                        Button {
                            downloadManager.downloadModel(model)
                        } label: {
                            HStack {
                                Image(systemName: "icloud.and.arrow.down")
                                Text("Download Recommended GGUF")
                                Spacer()
                            }
                        }
                    }
                }

                Section("Model Information") {
                    LabeledContent("Model ID", value: model.id)
                    if let lastModified = model.lastModified {
                        LabeledContent("Last Modified", value: lastModified.formatted(date: .abbreviated, time: .omitted))
                    }
                    if let author = model.author {
                        LabeledContent("Author", value: author)
                    }
                }

                if let siblings = model.siblings {
                    Section("Files (\(siblings.count))") {
                        ForEach(siblings, id: \.rfilename) { sibling in
                            HStack {
                                Image(systemName: sibling.rfilename.lowercased().hasSuffix(".gguf") ? "cpu" : "doc")
                                    .foregroundColor(.secondary)
                                Text(sibling.rfilename)
                                    .font(.caption)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Model Details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadDetails()
        }
        .onAppear {
            Task {
                await loadDetails()
            }
        }
    }

    private func loadDetails() async {
        isLoading = true
        errorMessage = nil
        do {
            let details = try await HuggingFaceAPIClient.shared.fetchModelDetails(id: modelId)
            await MainActor.run {
                self.model = details
                self.isLoading = false
                // Size estimation is tricky from just the model list,
                // but some models have it in metadata or we could fetch it.
                // For now, we'll placeholder it or try to find it in siblings if available.
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
