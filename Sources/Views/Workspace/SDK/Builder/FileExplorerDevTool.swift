import SwiftUI

struct FileExplorerDevTool: DevTool {
    let id = "file-explorer"
    let name = "File Explorer"
    let category = DevToolCategory.storage
    let icon = "folder.badge.gearshape"
    let description = "Browse and manage application files"

    func render() -> some View {
        FileExplorerView()
    }
}

struct FileExplorerView: View {
    @StateObject private var viewModel = FileExplorerViewModel()

    var body: some View {
        List {
            Section {
                if !viewModel.isAtRoot {
                    Button { viewModel.navigateUp() } label: {
                        Label("..", systemImage: "arrow.up.doc")
                    }
                }

                ForEach(viewModel.files) { file in
                    HStack {
                        Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundStyle(file.isDirectory ? Color.accentColor : .secondary)

                        VStack(alignment: .leading) {
                            Text(file.name).font(.subheadline)
                            Text(file.size).font(.caption2).foregroundStyle(.secondary)
                        }

                        Spacer()

                        if !file.isDirectory {
                            Button { viewModel.deleteFile(file) } label: {
                                Image(systemName: "trash").foregroundStyle(.red)
                            }
                        } else {
                            Button { viewModel.navigateInto(file) } label: {
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                }
            } header: {
                Text("Current Directory: \(viewModel.currentPath.lastPathComponent)")
            }
        }
        .refreshable { viewModel.load() }
        .onAppear { viewModel.load() }
    }
}

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let isDirectory: Bool
    let size: String
}

class FileExplorerViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var currentPath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    var isAtRoot: Bool {
        // Simplified root check
        currentPath.pathComponents.count <= 4
    }

    func load() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: currentPath, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: .skipsHiddenFiles)

            files = urls.map { url in
                let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                let size = ByteCountFormatter.string(fromByteCount: Int64(values?.fileSize ?? 0), countStyle: .file)
                return FileItem(name: url.lastPathComponent, path: url, isDirectory: values?.isDirectory ?? false, size: size)
            }.sorted { $0.isDirectory && !$1.isDirectory }
        } catch {
            files = []
        }
    }

    func navigateInto(_ file: FileItem) {
        currentPath = file.path
        load()
    }

    func navigateUp() {
        currentPath = currentPath.deletingLastPathComponent()
        load()
    }

    func deleteFile(_ file: FileItem) {
        try? FileManager.default.removeItem(at: file.path)
        load()
    }
}

#Preview {
    FileExplorerView()
}
