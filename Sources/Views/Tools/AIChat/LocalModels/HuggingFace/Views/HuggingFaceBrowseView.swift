import SwiftUI
import Combine

struct HuggingFaceBrowseView: View {
    @ObservedObject private var client = HuggingFaceAPIClient.shared
    @State private var models: [HFModel] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var offset = 0
    private let limit = 20

    var body: some View {
        List {
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }

            ForEach(models) { model in
                NavigationLink(destination: HFModelDetailView(modelId: model.id)) {
                    VStack(alignment: .leading) {
                        Text(model.id)
                            .font(.headline)
                        if let downloads = model.downloads {
                            Text("\(downloads) downloads")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onAppear {
                    if model == models.last && !isLoading {
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
        }
        .navigationTitle("HuggingFace")
        .searchable(text: $searchText)
        .refreshable {
            await search(isRefreshing: true)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink(destination: HFInstalledModels()) {
                        Image(systemName: "folder.badge.person.crop")
                    }
                    NavigationLink(destination: HFRecommendationView()) {
                        Image(systemName: "sparkles")
                    }
                }
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            Task {
                await search()
            }
        }
        .onAppear {
            Task {
                await search()
            }
        }
    }

    private func search(isRefreshing: Bool = false) async {
        if isLoading && !isRefreshing { return }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
            if !isRefreshing {
                models = []
                offset = 0
            }
        }

        do {
            let results = try await client.searchModels(query: searchText, limit: limit, offset: 0)
            await MainActor.run {
                self.models = results
                self.offset = results.count
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func loadMore() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                let results = try await client.searchModels(query: searchText, limit: limit, offset: offset)
                await MainActor.run {
                    self.models.append(contentsOf: results)
                    self.offset += results.count
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
}
