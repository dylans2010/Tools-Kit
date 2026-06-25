import SwiftUI

struct HFInstalledModels: View {
    @State private var downloadedModels: [InstalledModel] = []
    @State private var isLoading = false
    @ObservedObject var downloadManager = HuggingFaceDownloadManager.shared
    @Environment(\.dismiss) private var dismiss

    struct InstalledModel: Identifiable {
        let id: String // Original ID (e.g. "author/model")
        let folderName: String // folder name (e.g. "author_model")
        let url: URL
        let size: Int64
        let files: [String]
    }

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if downloadedModels.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "folder.badge.minus")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No models installed.")
                        .font(.headline)
                    Text("Browse HuggingFace to find and download models.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .listRowBackground(Color.clear)
            } else {
                Section {
                    Button(role: .destructive) {
                        bulkDelete()
                    } label: {
                        Label("Bulk Delete All Models", systemImage: "trash.fill")
                    }
                }

                Section("Installed Models") {
                    ForEach(downloadedModels) { model in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(model.id)
                                    .font(.headline)
                                Spacer()
                                Text(formatSize(model.size))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("\(model.files.count) files")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteModel(model)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteModel(model)
                            } label: {
                                Label("Delete Model", systemImage: "trash")
                            }

                            Button {
                                openInFiles(model)
                            } label: {
                                Label("Show in Files", systemImage: "folder")
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    openStorageDirectory()
                } label: {
                    Label("Open HuggingFace Directory", systemImage: "folder.fill")
                }
            }
        }
        .navigationTitle("Installed Models")
        .onAppear {
            loadModels()
        }
    }

    private func loadModels() {
        isLoading = true
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let hfRootFolder = paths[0].appendingPathComponent("Models", isDirectory: true)

        guard let folders = try? FileManager.default.contentsOfDirectory(at: hfRootFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            isLoading = false
            return
        }

        var models: [InstalledModel] = []
        for folder in folders {
            if folder.hasDirectoryPath {
                let folderName = folder.lastPathComponent
                let modelID = folderName.replacingOccurrences(of: "_", with: "/")

                let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
                let rfilenames = files.map { $0.lastPathComponent }

                var totalSize: Int64 = 0
                for file in files {
                    let attrs = try? FileManager.default.attributesOfItem(atPath: file.path)
                    totalSize += attrs?[.size] as? Int64 ?? 0
                }

                models.append(InstalledModel(id: modelID, folderName: folderName, url: folder, size: totalSize, files: rfilenames))
            }
        }
        self.downloadedModels = models
        isLoading = false
    }

    private func deleteModel(_ model: InstalledModel) {
        downloadManager.deleteDownloadedModel(id: model.id)
        loadModels()
    }

    private func bulkDelete() {
        for model in downloadedModels {
            downloadManager.deleteDownloadedModel(id: model.id)
        }
        loadModels()
    }

    private func openInFiles(_ model: InstalledModel) {
        let url = model.url
        // Use share sheet to reveal the folder or try to open it
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func openStorageDirectory() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let hfRootFolder = paths[0].appendingPathComponent("Models", isDirectory: true)

        let activityVC = UIActivityViewController(activityItems: [hfRootFolder], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
