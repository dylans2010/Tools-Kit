import SwiftUI

struct DeveloperStorageUsageView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddStorage = false
    @State private var selectedAppID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                storageHeader

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Active Storage").font(.headline)
                        Spacer()
                        Button { showingAddStorage = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }

                    ForEach(storageNodes) { node in
                        storageCard(node)
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Storage Usage")
        .alert("Provision Storage", isPresented: $showingAddStorage) {
            Button("Cancel", role: .cancel) { }
            Button("Provision 10GB") { /* Provision logic */ }
        } message: {
            Text("Select an app and size to provision additional block storage.")
        }
    }

    private var storageHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Utilization").font(.headline)
                    Text("Last audit: 12m ago").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "archivebox.fill").foregroundStyle(.purple).font(.title2)
            }

            HStack(spacing: 20) {
                storageMetric(label: "Used", value: "142 GB", color: .purple)
                storageMetric(label: "Available", value: "858 GB", color: .secondary)
                storageMetric(label: "Objects", value: "1.2M", color: .blue)
            }

            ProgressView(value: 0.14)
                .tint(.purple)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    private func storageMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func storageCard(_ node: StorageNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(node.name).font(.subheadline.bold())
                Spacer()
                Text(node.type).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(node.usage * 100))% full").font(.system(size: 8)).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(node.usedSize) / \(node.totalSize)").font(.system(size: 8)).foregroundStyle(.secondary)
                }
                ProgressView(value: node.usage)
                    .progressViewStyle(.linear)
                    .tint(.purple)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private var storageNodes: [StorageNode] {
        [
            StorageNode(name: "Production Assets", type: "Object S3", usedSize: "120GB", totalSize: "500GB", usage: 0.24),
            StorageNode(name: "Log Archive", type: "Cold Storage", usedSize: "22GB", totalSize: "500GB", usage: 0.04)
        ]
    }
}

struct StorageNode: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let usedSize: String
    let totalSize: String
    let usage: Double
}
