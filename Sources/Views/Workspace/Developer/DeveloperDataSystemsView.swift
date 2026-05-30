import SwiftUI

struct DatabaseInspectorView: View {
    @ObservedObject var dbService = DatabaseManagementService.shared
    @State private var isRefreshing = false

    var body: some View {
        List {
            Section("Data Entities") {
                if dbService.entities.isEmpty {
                    Text("No database entities found.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(dbService.entities) { entity in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entity.name).font(.subheadline.bold())
                                Text("\(entity.recordCount) records").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ByteCountFormatter().string(fromByteCount: entity.sizeInBytes))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Storage Maintenance") {
                Button(role: .destructive) {
                    Task {
                        await dbService.clearCache()
                    }
                } label: {
                    Label("Prune Orphaned Records", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Database Inspector")
        .refreshable {
            dbService.refreshStats()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    dbService.refreshStats()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

struct CacheManagerView: View {
    @ObservedObject var dbService = DatabaseManagementService.shared
    @State private var cacheSize: Int64 = 1024 * 1024 * 15 // Simulated 15MB real cache

    var body: some View {
        List {
            Section("Cache Status") {
                HStack {
                    Text("Total Cache Size")
                    Spacer()
                    Text(ByteCountFormatter().string(fromByteCount: cacheSize)).bold()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Cache Usage").font(.caption).foregroundStyle(.secondary)
                    ProgressView(value: 0.35) // Example usage ratio
                        .tint(.orange)
                }
                .padding(.vertical, 4)
            }

            Section("Actions") {
                Button("Clear Image Cache") {
                    cacheSize = 0
                }
                Button("Clear Network Cache") {
                    // Logic for network cache clearing
                }
            }
        }
        .navigationTitle("Cache Manager")
    }
}
