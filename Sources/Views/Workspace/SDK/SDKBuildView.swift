import SwiftUI

struct SDKBuildView: View {
    @StateObject private var projectManager = SDKProjectManager.shared
    @State private var isBuilding = false
    @State private var buildProgress: Double = 0.0
    @State private var exportedURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let project = projectManager.currentProject {
                Section("Project Summary") {
                    LabeledContent("Name", value: project.name)
                    LabeledContent("Created", value: project.createdAt.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Health", value: project.healthStatus.rawValue.capitalized)
                }

                Section("Inclusions") {
                    LabeledContent("Scopes", value: "\(project.enabledScopes.count)")
                    LabeledContent("Plugins", value: "\(project.enabledPluginIDs.count)")
                    LabeledContent("Tools", value: "\(project.enabledToolIDs.count)")
                    LabeledContent("Connectors", value: "\(project.enabledConnectorIDs.count)")
                    LabeledContent("Automations", value: "\(project.automationRules.count)")
                }

                Section {
                    Button(action: startBuild) {
                        if isBuilding {
                            HStack {
                                Text("Building...")
                                Spacer()
                                ProgressView(value: buildProgress)
                                    .frame(width: 100)
                            }
                        } else {
                            Text("Build & Export")
                        }
                    }
                    .disabled(isBuilding)
                }

                if let url = exportedURL {
                    Section {
                        HStack {
                            Image(systemName: "doc.zipper")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(url.lastPathComponent).font(.headline)
                                Text("Size: \(fileSizeString(url))").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            ShareLink(item: url)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Build")
    }

    private func fileSizeString(_ url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? UInt64 else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func startBuild() {
        guard let project = projectManager.currentProject else { return }
        isBuilding = true
        errorMessage = nil
        exportedURL = nil

        Task {
            await MainActor.run { buildProgress = 0.1 }

            do {
                await MainActor.run { buildProgress = 0.3 }
                let config = SDKExportConfig(
                    projectName: project.name,
                    scopes: project.enabledScopes.compactMap { scopeStr in SDKScope.allCases.first { String(describing: $0) == scopeStr } },
                    pluginIDs: project.enabledPluginIDs,
                    toolIDs: project.enabledToolIDs,
                    connectorIDs: project.enabledConnectorIDs,
                    automationRules: project.automationRules,
                    exportedAt: Date()
                )
                await MainActor.run { buildProgress = 0.6 }
                let url = try await SDKExportService().export(config: config)
                await MainActor.run {
                    buildProgress = 1.0
                    self.exportedURL = url
                    self.isBuilding = false
                    projectManager.currentProject?.lastBuiltAt = Date()
                    try? projectManager.save()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isBuilding = false
                }
            }
        }
    }
}
