import SwiftUI

struct FileExplorerDevTool: DevTool {
    let id = "file-explorer"
    let name = "File Explorer"
    let category = DevToolCategory.storage
    let icon = "folder"
    let description = "Browse application sandboxed files"

    func render() -> some View {
        FileExplorerView()
    }
}

struct FileExplorerView: View {
    @State private var items: [URL] = []

    var body: some View {
        List {
            ForEach(items, id: \.self) { url in
                HStack {
                    Image(systemName: url.hasDirectoryPath ? "folder" : "doc")
                    VStack(alignment: .leading) {
                        Text(url.lastPathComponent)
                        Text(url.path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            loadFiles()
        }
    }

    private func loadFiles() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let content = try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) {
            items = content
        }
    }
}
