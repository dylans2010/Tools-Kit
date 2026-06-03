import SwiftUI

private class StorageService: ObservableObject {
    static let shared = StorageService()
    @Published var totalUsed: Int64 = 0
    @Published var totalAvailable: Int64 = 0
    @Published var breakdown: [StorageCategory] = []
    @Published var storageNodes: [StorageNode] = []

    private init() {}

    func refresh() { }

    func provisionStorage(appID: UUID, name: String, type: String, sizeGB: Int) async throws { }
}

private struct StorageCategory: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var bytes: Int64
}

struct DeveloperStorageUsageView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var storageService = StorageService.shared
    @State private var showingAddStorage = false
    @State private var selectedAppID: UUID?

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

                    if storageService.storageNodes.isEmpty {
                        EmptyStateView(icon: "archivebox", title: "No Storage", message: "Provision your first storage instance.")
                    } else {
                        ForEach(storageService.storageNodes) { node in
                            storageCard(node)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Storage")
        .alert("Provision Storage", isPresented: $showingAddStorage) {
            Button("Cancel", role: .cancel) { }
            Button("Provision 10GB") {
                if let appID = selectedAppID {
                    Task {
                        try? await storageService.provisionStorage(appID: appID, name: "New Storage", type: "Block Storage", sizeGB: 10)
                    }
                }
            }
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
                storageMetric(label: "Used", value: "0 GB", color: .purple)
                storageMetric(label: "Total Cap", value: "\(storageService.storageNodes.count * 10) GB", color: .secondary)
                storageMetric(label: "Avg Load", value: "0%", color: .blue)
            }

            ProgressView(value: 0.0)
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
