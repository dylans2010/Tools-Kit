import SwiftUI

struct SDKResourceInspectorView: View {
    @State private var showingDetails = false

    var body: some View {
        List {
            Section("Assets") {
                ResourceRow(name: "Icons & Symbols", count: 142, size: "1.2 MB")
                ResourceRow(name: "Localized Strings", count: 8, size: "45 KB")
                ResourceRow(name: "Custom Fonts", count: 2, size: "3.4 MB")
            }

            Section("Modules") {
                ResourceRow(name: "Core Infrastructure", count: 24, size: "8.2 MB")
                ResourceRow(name: "Networking Layer", count: 12, size: "1.5 MB")
                ResourceRow(name: "UI Components", count: 45, size: "2.1 MB")
            }

            Section("Clean Up") {
                Button(role: .destructive) {
                    // Logic to prune unused resources
                } label: {
                    Label("Prune Unused Assets", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Resource Inspector")
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
