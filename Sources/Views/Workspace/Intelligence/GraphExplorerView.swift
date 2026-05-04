import SwiftUI

struct GraphExplorerView: View {
    @StateObject private var manager = ContextGraphManager.shared
    @StateObject private var dataStore = UnifiedDataStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Unified Context Graph")
                    .font(.title2.bold())
                    .padding(.horizontal)

                ForEach(dataStore.entities) { entity in
                    VStack(alignment: .leading) {
                        Text(entity.title).font(.headline)
                        let related = manager.getRelatedEntities(for: entity.id)
                        if related.isEmpty {
                            Text("No connections").font(.caption).foregroundColor(.secondary)
                        } else {
                            ForEach(related) { rel in
                                Text("→ \(rel.title)").font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Graph Explorer")
    }
}
