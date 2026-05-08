import SwiftUI

struct SDKDataControlView: View {
    @ObservedObject var store = SDKDataStore.shared
    @State private var selectedCollection: String?

    var stats: [String: Int] {
        store.collectionStats()
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Persistence Status")
                            .font(.headline)
                        Text(store.isInitialized ? "Online" : "Offline")
                            .font(.subheadline)
                            .foregroundColor(store.isInitialized ? .green : .red)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Total Records")
                            .font(.headline)
                        Text("\(store.totalRecords)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Database Engine")
            }

            Section {
                if stats.isEmpty {
                    Text("No data collections found.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stats.keys.sorted(), id: \.self) { key in
                        NavigationLink {
                            SDKCollectionDetailView(collectionName: key)
                        } label: {
                            HStack {
                                Label(key, systemImage: "tablecells")
                                Spacer()
                                Text("\(stats[key] ?? 0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Collections")
            }

            Section {
                Button(role: .destructive) {
                    // Logic to wipe database would go here in a full implementation
                } label: {
                    Label("Wipe Data Store", systemImage: "trash")
                }

                Button {
                    store.flush()
                } label: {
                    Label("Force Flush", systemImage: "arrow.down.doc")
                }
            } header: {
                Text("Maintenance")
            }
        }
        .navigationTitle("Data Control")
    }
}

struct SDKCollectionDetailView: View {
    let collectionName: String

    var body: some View {
        List {
            Text("Inspecting collection: \(collectionName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // In a full implementation, we would list records here using SDKDatabase listFiles
            // and decoding some samples.
        }
        .navigationTitle(collectionName)
    }
}
