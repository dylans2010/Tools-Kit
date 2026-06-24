import SwiftUI
import Combine

struct HuggingFaceBrowseView: View {
    @ObservedObject private var client = HuggingFaceAPIClient.shared
    @State private var models: [HFModel] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }

            ForEach(models) { model in
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

            if isLoading {
                ProgressView()
            }
        }
        .navigationTitle("HuggingFace")
        .searchable(text: $searchText)
        .onChange(of: searchText) { oldValue, newValue in
            search()
        }
        .onAppear {
            search()
        }
    }

    private func search() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let results = try await client.searchModels(query: searchText)
                await MainActor.run {
                    self.models = results
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
