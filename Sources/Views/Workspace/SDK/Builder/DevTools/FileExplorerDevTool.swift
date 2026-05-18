import SwiftUI

struct FileExplorerTool: DevTool {
    let id = UUID()
    let name = "File Explorer"
    let category: DevToolCategory = .storage
    let icon = "folder"
    let description = "Browse the app sandbox file system"
    func render() -> some View { FileExplorerDevToolView() }
}

struct FileExplorerDevToolView: View {
    @State private var currentPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    @State private var items: [FileItem] = []
    @State private var errorMsg: String?
    @State private var pathHistory: [URL] = []

    struct FileItem: Identifiable {
        let id = UUID()
        let name: String
        let url: URL
        let isDirectory: Bool
        let size: Int64
        let modified: Date?
    }

    var body: some View {
        Form {
            Section("Path") {
                Text(currentPath.path)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                HStack {
                    Button("Documents") { navigateTo(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!) }
                    Button("Caches") { navigateTo(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!) }
                    Button("Temp") { navigateTo(FileManager.default.temporaryDirectory) }
                }
                .font(.caption)
                if !pathHistory.isEmpty {
                    Button("Back") {
                        if let prev = pathHistory.popLast() { currentPath = prev; loadItems() }
                    }
                }
            }
            if let errorMsg {
                Section { Label(errorMsg, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            Section("Contents (\(items.count))") {
                ForEach(items) { item in
                    Button {
                        if item.isDirectory {
                            pathHistory.append(currentPath)
                            navigateTo(item.url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: item.isDirectory ? "folder.fill" : fileIcon(item.name))
                                .foregroundStyle(item.isDirectory ? .blue : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.subheadline)
                                HStack {
                                    if !item.isDirectory {
                                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                    }
                                    if let mod = item.modified {
                                        Text(mod, style: .date)
                                    }
                                }
                                .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if item.isDirectory {
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("File Explorer")
        .onAppear { loadItems() }
    }

    private func navigateTo(_ url: URL) {
        currentPath = url
        loadItems()
    }

    private func loadItems() {
        errorMsg = nil
        do {
            let fm = FileManager.default
            let urls = try fm.contentsOfDirectory(at: currentPath, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            items = urls.map { url in
                let vals = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                return FileItem(
                    name: url.lastPathComponent, url: url,
                    isDirectory: vals?.isDirectory ?? false,
                    size: Int64(vals?.fileSize ?? 0),
                    modified: vals?.contentModificationDate
                )
            }.sorted { $0.isDirectory && !$1.isDirectory ? true : (!$0.isDirectory && $1.isDirectory ? false : $0.name < $1.name) }
        } catch {
            errorMsg = error.localizedDescription
            items = []
        }
    }

    private func fileIcon(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "json": return "doc.text"
        case "plist", "xml": return "doc.richtext"
        case "sqlite", "db": return "cylinder"
        case "png", "jpg", "jpeg": return "photo"
        default: return "doc"
        }
    }
}
