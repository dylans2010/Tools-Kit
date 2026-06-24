import SwiftUI

struct HFModelDetailView: View {
    let modelId: String
    @State private var model: HFModel?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @ObservedObject var downloadManager = HuggingFaceDownloadManager.shared

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

                Section("Download GGUF") {
                    if let downloadTask = downloadManager.activeDownloads[model.id] {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(downloadTask.status.rawValue.capitalized)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("\(Int(downloadTask.progress * 100))%")
                                    .font(.caption)
                            }
                            ProgressView(value: downloadTask.progress)

                            if downloadTask.status == .downloading {
                                Button(role: .destructive) {
                                    downloadManager.cancelDownload(id: model.id)
                                } label: {
                                    Text("Cancel Download")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    } else {
                        Button {
                            downloadManager.downloadModel(model)
                        } label: {
                            HStack {
                                Image(systemName: "icloud.and.arrow.down")
                                Text("Download Model")
                                Spacer()
                            }
                        }
                    }
                }

                if let siblings = model.siblings {
                    Section("Files") {
                        ForEach(siblings, id: \.rfilename) { sibling in
                            Text(sibling.rfilename)
                                .font(.caption)
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
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
