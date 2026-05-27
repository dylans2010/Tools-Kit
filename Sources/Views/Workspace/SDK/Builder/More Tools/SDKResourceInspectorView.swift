import SwiftUI

struct SDKResourceInspectorView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var showingPruneConfirmation = false
    @State private var pruneResults: String?

    @State private var assets: [ResourceItem] = []
    @State private var modules: [ResourceItem] = []
    @State private var totalSize: Int64 = 0
    @State private var isScanning = false

    struct ResourceItem: Identifiable {
        let id = UUID()
        let name: String
        var count: Int
        var size: Int64
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Managed Size")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(formatByteSize(totalSize))
                                .font(.title2.bold())
                        }
                        Spacer()
                        if isScanning {
                            ProgressView()
                        } else {
                            Button {
                                scanResources()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Assets") {
                if assets.isEmpty && !isScanning {
                    Text("No assets found in managed directories").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(assets) { item in
                        ResourceRow(name: item.name, count: item.count, size: formatByteSize(item.size))
                    }
                }
            }

            Section("Components") {
                if modules.isEmpty && !isScanning {
                    Text("No components found").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(modules) { item in
                        ResourceRow(name: item.name, count: item.count, size: formatByteSize(item.size))
                    }
                }
            }

            Section("Maintenance") {
                Button(role: .destructive) {
                    showingPruneConfirmation = true
                } label: {
                    Label("Clean Build Artifacts", systemImage: "trash")
                }
                .disabled(totalSize == 0 || isScanning)

                if let results = pruneResults {
                    Text(results)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Resource Inspector")
        .onAppear {
            scanResources()
        }
        .confirmationDialog("Clean Build Artifacts?", isPresented: $showingPruneConfirmation, titleVisibility: .visible) {
            Button("Clean", role: .destructive) {
                runPruning()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all generated .sdkbundle artifacts and temporary export files to reclaim space.")
        }
    }

    private func formatByteSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func scanResources() {
        isScanning = true
        assets = []
        modules = []
        totalSize = 0

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory

        do {
            let files = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])

            var sdkBundlesCount = 0
            var sdkBundlesSize: Int64 = 0

            var tempDocsCount = 0
            var tempDocsSize: Int64 = 0

            for file in files {
                let values = try file.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                let size = Int64(values.fileSize ?? 0)

                if file.pathExtension == "sdkbundle" {
                    sdkBundlesCount += 1
                    sdkBundlesSize += size
                } else if file.lastPathComponent.contains("encoded_") || file.lastPathComponent.contains("sdk_") {
                    tempDocsCount += 1
                    tempDocsSize += size
                }
            }

            if sdkBundlesCount > 0 {
                assets.append(ResourceItem(name: "SDK Bundles", count: sdkBundlesCount, size: sdkBundlesSize))
            }
            if tempDocsCount > 0 {
                assets.append(ResourceItem(name: "Temporary Artifacts", count: tempDocsCount, size: tempDocsSize))
            }

            // Also include project data counts
            if let project = projectManager.currentProject {
                modules.append(ResourceItem(name: "Enabled Plugins", count: project.enabledPluginIDs.count, size: 0))
                modules.append(ResourceItem(name: "Enabled Tools", count: project.enabledToolIDs.count, size: 0))
                modules.append(ResourceItem(name: "Automation Rules", count: project.automationRules.count, size: 0))
            }

            self.totalSize = sdkBundlesSize + tempDocsSize
            self.isScanning = false
        } catch {
            self.isScanning = false
        }
    }

    private func runPruning() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        var deletedCount = 0
        var savedBytes: Int64 = 0

        do {
            let files = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                if file.pathExtension == "sdkbundle" || file.lastPathComponent.contains("encoded_") {
                    let size = Int64((try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
                    try? fileManager.removeItem(at: file)
                    deletedCount += 1
                    savedBytes += size
                }
            }

            pruneResults = "Cleaned \(deletedCount) items, reclaimed \(formatByteSize(savedBytes))."
            scanResources()

            SDKAuditLogger.shared.log(
                eventType: .dataAccess,
                projectID: projectManager.currentProject?.id,
                scope: "system.cleanup",
                message: "Manually purged build artifacts from temporary storage."
            )
        } catch {
            // Silently fail if cleanup fails
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
            if size != "0 bytes" {
                Text(size).font(.caption.monospaced())
            }
        }
    }
}
