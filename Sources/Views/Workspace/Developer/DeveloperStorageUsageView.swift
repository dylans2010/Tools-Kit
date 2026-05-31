import SwiftUI

struct DeveloperStorageUsageView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddStorage = false
    @State private var selectedAppID: UUID?

    let storageNodes: [StorageNode] = [
        StorageNode(name: "Production Assets", type: "Object S3", usedSize: "120GB", totalSize: "500GB", usage: 0.24),
        StorageNode(name: "Log Archive", type: "Cold Storage", usedSize: "22GB", totalSize: "500GB", usage: 0.04),
        StorageNode(name: "Redis Cache", type: "In-Memory", usedSize: "4.2GB", totalSize: "16GB", usage: 0.26)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                storageHeader

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Provisioned Instances").font(.headline)
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
        .navigationTitle("Storage")
        .alert("Provision Storage", isPresented: $showingAddStorage) {
            Button("Cancel", role: .cancel) { }
            Button("Provision 10GB") { /* logic */ }
        } message: {
            Text("Select an application and size to provision additional block storage capacity.")
        }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private var storageHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fleet Utilization").font(.headline)
                    Text("Last audit: \(Date().formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "archivebox.fill").foregroundStyle(.purple).font(.title2)
            }

            HStack(spacing: 32) {
                storageMetric(label: "Used", value: "146.2 GB", color: .purple)
                storageMetric(label: "Total Cap", value: "1,016 GB", color: .secondary)
                storageMetric(label: "Avg Load", value: "14%", color: .blue)
            }

            ProgressView(value: 0.14)
                .tint(.purple)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding()
    }

    private func storageMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.title3.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func storageCard(_ node: StorageNode) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name).font(.subheadline.bold())
                    Text(node.type).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                }
                Spacer()
                Text("HEALTHY").font(.system(size: 8, weight: .black)).foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(Int(node.usage * 100))% Capacity").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(node.usedSize) / \(node.totalSize)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                }
                ProgressView(value: node.usage)
                    .progressViewStyle(.linear)
                    .tint(node.usage > 0.8 ? .red : .purple)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
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
