import SwiftUI

struct SDKResourceInspectorView: View {
    @State private var showingPruneConfirmation = false
    @State private var isPruning = false
    @State private var pruneResults: String?

    @State private var assets = [
        ResourceItem(name: "Icons & Symbols", count: 142, size: 1.2),
        ResourceItem(name: "Localized Strings", count: 8, size: 0.045),
        ResourceItem(name: "Custom Fonts", count: 2, size: 3.4)
    ]

    @State private var modules = [
        ResourceItem(name: "Core Infrastructure", count: 24, size: 8.2),
        ResourceItem(name: "Networking Layer", count: 12, size: 1.5),
        ResourceItem(name: "UI Components", count: 45, size: 2.1)
    ]

    struct ResourceItem: Identifiable {
        let id = UUID()
        let name: String
        var count: Int
        var size: Double // in MB
    }

    var body: some View {
        List {
            Section("Assets") {
                ForEach(assets) { item in
                    ResourceRow(name: item.name, count: item.count, size: formatSize(item.size))
                }
            }

            Section("Modules") {
                ForEach(modules) { item in
                    ResourceRow(name: item.name, count: item.count, size: formatSize(item.size))
                }
            }

            Section("Clean Up") {
                if isPruning {
                    HStack {
                        ProgressView()
                        Text("Pruning unused resources...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    Button(role: .destructive) {
                        showingPruneConfirmation = true
                    } label: {
                        Label("Prune Unused Assets", systemImage: "trash")
                    }
                    .disabled(pruneResults != nil)
                }

                if let results = pruneResults {
                    Text(results)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Resource Inspector")
        .confirmationDialog("Prune Unused Assets?", isPresented: $showingPruneConfirmation, titleVisibility: .visible) {
            Button("Prune", role: .destructive) {
                runPruning()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will scan the SDK for resources that are not referenced in the code and remove them from the production bundle.")
        }
    }

    private func formatSize(_ mb: Double) -> String {
        if mb < 1.0 {
            return "\(Int(mb * 1024)) KB"
        } else {
            return String(format: "%.1f MB", mb)
        }
    }

    private func runPruning() {
        isPruning = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPruning = false
            let savedSize = Double.random(in: 0.5...2.5)
            pruneResults = "Scan complete. Pruned 18 unused assets, saving \(String(format: "%.1f", savedSize)) MB."

            // Simulate reduction in size
            if !assets.isEmpty {
                assets[0].count -= 12
                assets[0].size -= (savedSize * 0.8)
            }
        }
    }
}

private struct ResourceRow: View {
    let name: String
    let count: Int
    let size: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.subheadline.bold())
                Text("\(count) items").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(size).font(.caption.monospaced())
        }
    }
}
