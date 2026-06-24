import SwiftUI

struct HuggingFaceBrowseView: View {
    @StateObject private var apiClient = HuggingFaceAPIClient.shared
    @StateObject private var downloadManager = HuggingFaceDownloadManager.shared

    @State private var models: [HFModel] = []
    @State private var query = ""
    @State private var isLoading = false
    @State private var offset = 0
    @State private var canLoadMore = true
    @State private var showRecommendations = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                List {
                    Section {
                        Button {
                            showRecommendations = true
                        } label: {
                            Label("What's My Recommendation?", systemImage: "sparkles")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }

                    Section {
                        ForEach(models) { model in
                            modelRow(model)
                                .onAppear {
                                    if model == models.last && canLoadMore && !isLoading {
                                        loadMore()
                                    }
                                }
                        }

                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    } header: {
                        Text(query.isEmpty ? "Trending GGUF Models" : "Search Results")
                    }
                }
                .searchable(text: $query, prompt: "Search HuggingFace...")
                .onChange(of: query) { _, _ in
                    resetAndSearch()
                }
                .onAppear {
                    if models.isEmpty {
                        loadMore()
                    }
                }

            }
            .navigationTitle("HuggingFace")
            .sheet(isPresented: $showRecommendations) {
                HFRecommendationView()
            }
        }
    }

    private func modelRow(_ model: HFModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                Text(model.id)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    if let downloads = model.downloads {
                        Label("\(downloads)", systemImage: "arrow.down.circle")
                    }
                    if let likes = model.likes {
                        Label("\(likes)", systemImage: "heart")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            if let downloadTask = downloadManager.activeDownloads[model.id] {
                DownloadStateView(task: downloadTask)
            } else {
                Button {
                    downloadManager.downloadModel(model)
                } label: {
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func resetAndSearch() {
        models = []
        offset = 0
        canLoadMore = true
        loadMore()
    }

    private func loadMore() {
        guard !isLoading && canLoadMore else { return }
        isLoading = true

        Task {
            do {
                let newModels = try await apiClient.searchModels(query: query, offset: offset)
                await MainActor.run {
                    self.models.append(contentsOf: newModels)
                    self.offset += newModels.count
                    self.canLoadMore = newModels.count >= 20
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.canLoadMore = false
                }
            }
        }
    }
}

struct DownloadStateView: View {
    let task: HFDownloadTask

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            switch task.status {
            case .queued:
                Text("Queued")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            case .downloading:
                CircularProgressView(progress: task.progress)
                    .frame(width: 24, height: 24)
            case .paused:
                Image(systemName: "pause.circle")
                    .foregroundColor(.orange)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 3)
                .opacity(0.3)
                .foregroundColor(.blue)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
        }
    }
}
