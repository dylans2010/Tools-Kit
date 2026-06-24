import SwiftUI

struct OpenRouterFreeModelsView: View {
    @ObservedObject private var modelCatalog = AIModelCatalog.shared
    @State private var freeModels: [AIModel] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Finding free models...")
                    Spacer()
                }
            } else if freeModels.isEmpty {
                Text("No free models found on OpenRouter.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(freeModels) { model in
                    VStack(alignment: .leading) {
                        Text(model.name)
                            .font(.headline)
                        Text(model.id)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("OpenRouter Free Models")
        .task {
            await loadFreeModels()
        }
    }

    private func loadFreeModels() async {
        isLoading = true
        if modelCatalog.models(for: "openrouter").isEmpty {
            await modelCatalog.loadModels(for: "openrouter", force: false)
        }

        let allOpenRouter = modelCatalog.models(for: "openrouter")
        self.freeModels = allOpenRouter.filter { $0.id.lowercased().contains("free") }
        isLoading = false
    }
}
